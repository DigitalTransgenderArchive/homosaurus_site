class VersionRelease < ActiveRecord::Base
  belongs_to :vocabulary
  has_many :version_release_terms
  has_many :edit_requests

  # Remove terms from a release
  def delete_term_from_release(term_identifiers)
    vController = VocabularyController.new
    term_identifiers.each do |identifier|
      release_term = self.version_release_terms.find_by(term_identifier: identifier)
      term = Term.find_by(identifier: identifier)
      vController.clear_relations(term)
      release_term.destroy
      term.destroy
    end
  end

  def fix_duplicate_release_term(release_identifier, correct_identifier)
    vController = VocabularyController.new
    version_release_term = VersionReleaseTerm.find_by(term_identifier: release_identifier)
    release_term = Term.find_by(identifier: release_identifier)
    correct_term = Term.find_by(identifier: correct_identifier)

    release_term.broader.each do |broader|
      if broader.present?
        broader_object = Term.find_by(uri: broader)
        correct_term.broader = correct_term.broader + [broader_object.uri]
        correct_term.broader.uniq!
        broader_object.narrower = broader_object.narrower + [correct_term.uri]
        broader_object.narrower.uniq!
        broader_object.save
      end
    end

    release_term.narrower.each do |narrower|
      if narrower.present?
        narrower_object = Term.find_by(uri: narrower)
        correct_term.narrower = correct_term.narrower + [narrower_object.uri]
        correct_term.narrower.uniq!
        narrower_object.broader = narrower_object.broader + [correct_term.uri]
        narrower_object.broader.uniq!
        narrower_object.save
      end
    end

    release_term.related.each do |related|
      if related.present?
        related_object = Term.find_by(uri: related)
        correct_term.related = correct_term.related + [related_object.uri]
        correct_term.related.uniq!
        related_object.related = related_object.related + [correct_term.uri]
        related_object.related.uniq!
        related_object.save
      end
    end

    vController.clear_relations(release_term)
    version_release_term.destroy

      #term.destroy
    release_term.is_replaced_by = correct_term.uri
    release_term.visibility = "redirect"
    release_term.save!
  end

  def approved_edit_requests
    return self.edit_requests.where(status: "approved")
  end

  def all_cards_cache_key
    count, id_sum, changes_sum, status_sum = edit_requests.pluck(Arel.sql("COUNT(*)"), Arel.sql("SUM(id)"), Arel.sql("SUM(CRC32(my_changes))"), Arel.sql("SUM(CRC32(status))")).first
    [id, updated_at.to_i, "all", count, id_sum, changes_sum, status_sum, EditRequest.count, EditRequest.maximum(:id), Term.maximum(:updated_at).to_i]
  end

  def approved_cards_cache_key
    count, id_sum, changes_sum = approved_edit_requests.pluck(Arel.sql("COUNT(*)"), Arel.sql("SUM(id)"), Arel.sql("SUM(CRC32(my_changes))")).first
    [id, updated_at.to_i, count, id_sum, changes_sum, Term.maximum(:updated_at).to_i]
  end

  def statistics
    self.class.manage_statistics[id]
  end

  CARD_TYPES = %w[new_term redirected linked modified].freeze

  def self.edit_request_checksum
    EditRequest.pluck(Arel.sql("COUNT(*)"), Arel.sql("SUM(CRC32(CONCAT_WS(',', id, status, version_release_id, term_id, parent_id, prev_term_id)))")).first.map(&:to_i)
  end

  def self.edit_request_ids_without_previous
    Rails.cache.fetch(["edit-requests-without-previous", *edit_request_checksum]) do
      rows = EditRequest.pluck(:id, :term_id, :parent_id, :version_release_id, :prev_term_id)
      by_id = rows.map { |row| [row[0], row] }.to_h
      first_for_term = rows.group_by { |row| row[1] }.transform_values { |list| list.min_by { |id, _, _, release, _| [release.nil? ? 0 : 1, release.to_i, id] }[0] }
      first_child = rows.reject { |row| row[2].nil? }.group_by { |row| row[2] }.transform_values { |list| list.map(&:first).min }
      without_previous = lambda do |row|
        id, term_id, parent_id, _, prev_term_id = row
        if parent_id
          first_child[parent_id] == id && (by_id[parent_id].nil? || without_previous.(by_id[parent_id]))
        else
          first_for_term[term_id] == id && (prev_term_id.nil? || !first_for_term.key?(prev_term_id))
        end
      end
      rows.select { |row| without_previous.(row) }.map(&:first)
    end.to_set
  end

  def self.manage_statistics
    Rails.cache.fetch(["release-manage-statistics", *edit_request_checksum]) do
      new_ids = edit_request_ids_without_previous
      by_release = EditRequest.pluck(:id, :version_release_id).group_by(&:last)
      statuses = EditRequest.group(:version_release_id, :status).count
      VersionRelease.pluck(:id).map do |release_id|
        list = by_release.fetch(release_id, [])
        added = list.count { |id, _| new_ids.include?(id) }
        counts = statuses.select { |(rid, _), _| rid == release_id }.map { |(_, status), n| [status, n] }.to_h
        [release_id, {
          "terms_added" => added,
          "terms_modified" => list.size - added,
          "approved" => counts.fetch("approved", 0),
          "pending" => counts.fetch("pending", 0),
          "total" => counts.values.sum
        }]
      end.to_h
    end
  end

  def card_index(include_unapproved)
    scope = include_unapproved ? edit_requests : approved_edit_requests
    key = include_unapproved ? all_cards_cache_key : approved_cards_cache_key
    Rails.cache.fetch(["release-card-index", *key]) do
      rows = scope.pluck(:id, :term_id, :status, :created_at, :my_changes)
      new_ids = VersionRelease.edit_request_ids_without_previous
      children = EditRequest.where(parent_id: rows.map(&:first)).pluck(:parent_id, :creator_id).group_by(&:first)
      suggesters = User.joins(:roles).where(roles: { name: "suggester" }).distinct.pluck(:id).to_set
      term_labels = Term.where(id: rows.map { |row| row[1] }.compact.uniq).pluck(:id, :pref_label).to_h
      rows.map do |id, term_id, status, created_at, changes|
        changes ||= {}
        redirect = changes[Relation::Redirects_to] || []
        deletion = redirect.any? && redirect[0][2].to_i == 0
        linked = [Relation::Broader, Relation::Narrower, Relation::Related].any? { |rel| (changes[rel] || []).any? }
        type = if new_ids.include?(id) then "new_term" elsif redirect.any? && !deletion then "redirected" elsif linked then "linked" else "modified" end
        kids = children[id] || []
        suggested = kids.any? && status != "approved" && kids.any? { |_, creator| suggesters.include?(creator) }
        label = (changes[Relation::Pref_label] || []).first&.at(2) || term_labels[term_id]
        { "id" => id, "type" => type, "status" => status, "suggested" => suggested, "label" => label.to_s, "time" => created_at.to_s }
      end
    end
  end
  
  def self.term_totals(releases)
    latest = releases.select { |r| r.status == "Published" }.group_by(&:vocabulary_id).transform_values { |rs| rs.max_by(&:id).id }
    releases.map do |release|
      path = Rails.root.join("public", "static_dumps", release.vocabulary.identifier, "#{release.release_identifier}.nt")
      total = if File.exist?(path)
        Rails.cache.fetch(["release-term-total", path.to_s, File.mtime(path).to_i]) do
          subjects = {}
          File.foreach(path) { |line| subjects[line[/\A<[^>]+>/]] = true if line.include?("core#prefLabel>") }
          subjects.size
        end
      elsif latest[release.vocabulary_id] == release.id
        release.vocabulary.terms.where(visibility: "visible").count
      elsif release.status == "Pending" && release.id > latest[release.vocabulary_id].to_i
        release.vocabulary.terms.where(visibility: "visible").count + release.edit_requests.joins(:term).where(terms: { visibility: "pending" }).distinct.count(:term_id)
      end
      [release.id, total]
    end.to_h
  end

  def self.list_statistics
    approved = EditRequest.where(status: "approved").where.not(version_release_id: nil)
    key = ["release-statistics", *approved.pluck(Arel.sql("COUNT(*)"), Arel.sql("MAX(id)"), Arel.sql("SUM(CRC32(my_changes))")).first]
    Rails.cache.fetch(key) do
      state = {}
      stats = {}
      approved.order(:id).pluck(:term_id, :version_release_id, :my_changes).each do |term_id, release_id, changes|
        s = (stats[release_id] ||= { "new" => {}, "updated" => {}, "translations" => 0 })
        s["new"][term_id] = true unless state.key?(term_id)
        values = (state[term_id] ||= {})
        plus = []
        minus = []
        (changes.is_a?(Hash) ? changes : {}).each do |relation, ops|
          next unless ops.is_a?(Array)
          ops.each do |op|
            next unless op.is_a?(Array) && op.size > 1
            (op[0] == "+" ? plus : minus) << [relation, *op[1..-1]] if %w[+ -].include?(op[0])
          end
        end
        removed = (minus - plus).select { |k| values.delete(k) }
        added = (plus - minus).reject { |k| values.key?(k) }
        added.each { |k| values[k] = true }
        s["updated"][term_id] = true if (added.any? || removed.any?) && !s["new"].key?(term_id)
        s["translations"] += added.count { |relation, lang, _| relation == Relation::Pref_label && lang.present? && !lang.to_s.start_with?("en") }
      end
      stats.transform_values do |s|
        { "new" => s["new"].size, "updated" => s["updated"].size, "translations" => s["translations"] }
      end
    end
  end

  def self.get_next_identifier(change_type)
    current_identifier = VersionRelease.all()[-1].release_identifier
    last_published = VersionRelease.where(status: "Published").last
    #current_identifier = last_published.release_identifier
    ci_parts = current_identifier.split(".").map{ |x| x.to_i }
    #while VersionRelease.where(release_identifier: ci_parts.join(".")).count != 0
    if change_type == "Major"
      ci_parts[0] += 1
      ci_parts[1] = 0
      ci_parts[2] = 0
    elsif change_type == "Minor"
      ci_parts[1] += 1
      ci_parts[2] = 0
    elsif change_type == "Patch"
      ci_parts[2] += 1
    end
    #end
    return ci_parts.join(".")
  end
  # Returns whether this version release can be published
  def publishable?
    # If another release has since been published, return false
    if VersionRelease.where("id > #{self.id}").where(status: "Published").count > 0
      return false
    end
    # If there is a pending release preceding this, return false
    if VersionRelease.where("id < #{self.id}").where(status: "Pending").count == 0
      return false
    end
    return true
  end

  # Return all terms that exist in this version
  def terms_in_version()
    #return self.vocabulary.terms.reject{|t| t.first_introduced().id > self.id}
    #return self.vocabulary.terms.reject{|t| t.visibility == "pending" or t.first_introduced().id > self.id}
    return self.vocabulary.terms.reject{|t| t.visibility == "pending" or t.first_introduced().id > self.id or t.is_replaced_by.present?}
  end
  
  def generate_static_datafile(data, extension)

    outpath = Rails.root.join("public", "static_dumps", self.vocabulary.identifier, self.release_identifier + ".#{extension}")
    pp "==== WRITING #{outpath.to_s} ===="
    
    File.open(outpath, "w") {|file|
      file.write(data)
    }
    pp "==== DONE ===="
    
  end
  def generate_static_data
    pp "=== Generating static datafiles for v#{self.release_identifier} ==="
    terms = self.terms_in_version()
    pp "==== Building json-derived graph ==="
    graph = Term.all_terms_full_graph(terms, include_lang: self.vocabulary.id >= 4, version_release: self)

    generate_static_datafile(graph.dump(:jsonld, standard_prefixes: true), "jsonld")
    generate_static_datafile(graph.dump(:ttl, standard_prefixes: true), "ttl")
    generate_static_datafile(graph.dump(:ntriples), "nt")

    generate_static_datafile(Term.csv_download(terms, self), "csv")

    pp "==== Building xml-derived graph ==="
    
    xml_graph = Term.xml_basic_for_terms(terms, version_release: self)
    generate_static_datafile(xml_graph, "xml")

    marc_graph = Nokogiri::XSLT(File.read(Rails.root.join('app', 'assets', 'xslt', 'homosaurus_xml.xsl')))
    marc_graph2 = marc_graph.transform(Nokogiri::XML(xml_graph))

    generate_static_datafile(marc_graph2, "marc")
    
  end

  def generate_static_legacy_data
    pp "=== Generating legacy static datafiles for v#{self.release_identifier} ==="
    terms = self.terms_in_version()
    pp "==== Building json-derived graph ==="
    graph = Term.all_terms_full_graph(terms, include_lang: false, version_release: self)

    generate_static_datafile(graph.dump(:jsonld, standard_prefixes: true), "legacy.jsonld")
    generate_static_datafile(graph.dump(:ttl, standard_prefixes: true), "legacy.ttl")
    generate_static_datafile(graph.dump(:ntriples), "legacy.nt")
  end

end
