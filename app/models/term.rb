class Term < ActiveRecord::Base
  has_many :comments, as: :commentable
  has_many :vote_statuses, as: :votable
  include TermAssignments
  include ::Hist::Model

  has_hist associations: {all: {}}
  before_destroy :remove_from_solr
  after_save :send_solr

  belongs_to :vocabulary
  has_many :version_release_term
  has_many :term_relationships, dependent: :destroy
  has_many :relations, :through => :term_relationships

  has_many :edit_requests, -> { order 'version_release_id' }

  serialize :labels, Array
  serialize :labels_language, Array
  serialize :alt_labels, Array
  serialize :alt_labels_language, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array
  serialize :close_match, Array
  serialize :exact_match, Array
  serialize :close_match_homosaurus, Array
  serialize :exact_match_homosaurus, Array
  serialize :close_match_lcsh, Array
  serialize :exact_match_lcsh, Array
  serialize :contributors, Array
  serialize :sources, Array

  def self.mint(vocab_id: Vocabulary.latest)
    numeric_pid = Term.where(vocabulary_identifier: vocab_id).maximum(:numeric_pid) || 0
    numeric_pid = numeric_pid + 1
    numeric_pid
  end
  # Returns a term given vocabulary_identifier and homoit identifier
  def self.get(vocab_id, identifier)
    return Vocabulary.find_by(identifier: vocab_id).terms.find_by(identifier: identifier)
  end

  def self.get_from_uri(uri)
    v, i = uri.split("/").last(2)
    return Vocabulary.find_by(identifier: v).terms.find_by(identifier: i)
  end

  def self.find_with_conditions(model, q:, rows:, fl:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = "active_fedora_model_ssi:#{model}"
    result = DSolr.find(opts)
    result
  end

  def self.show_fields
    ['prefLabel', 'altLabel', 'description', 'identifier', 'issued', 'modified', 'exactMatch', 'closeMatch']
  end

  def self.get_values(field, obj)
    case field
    when "identifier"
      [obj["identifier_ssi"]] || []
    when "prefLabel"
      obj["prefLabel_ssim"] || []
    when "altLabel"
      obj["altLabel_ssim"] || []
    when "description"
      [obj["description_ssi"]] || []
    when "issued"
      obj["date_created_ssim"] || []
    when "modified"
      obj["date_created_ssim"] || []
    when "exactMatch"
      obj["exactMatch_ssim"] || []
    when "closeMatch"
      obj["closeMatch_ssim"] || []
    when "related"
      obj["related_ssim"] || []
    when "broader"
      obj["broader_ssim"] || []
    when "narrower"
      obj["narrower_ssim"] || []
    when "isReplacedBy"
      obj["isReplacedBy_ssim"] || []
    when "replaces"
      obj["replaces_ssim"] || []
    else
      [nil]
    end
  end

  def self.getLabel field
    case field
    when "identifier"
      "<a class='text-white' href='http://purl.org/dc/terms/identifier' target='blank' title='Definition of Identifier in the Dublin Core Terms Vocabulary'>Identifier</a>"
    when "prefLabel"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Preferred Label in the SKOS Vocabulary'>Preferred Term</a>"
    when "label"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Label in the SKOS Vocabulary'>Other Preferred Terms (usually translations)</a>"
    when "altLabel"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#altLabel' target='blank'  title='Definition of Alternative Label in the SKOS Vocabulary'>Alternative Term (Use For)</a>"
    when "description"
      "<a class='text-white' href='http://www.w3.org/2000/01/rdf-schema#comment' target='blank'  title='Definition of Comment in the RDF Schema Vocabulary'>Description (Scope Note)</a>"
    when "issued"
      "<a class='text-white' href='http://purl.org/dc/terms/issued' target='blank'  title='Definition of Issued in the Dublin Core Terms Vocabulary'>Issued (Created)</a>"
    when "modified"
      "<a class='text-white' href='http://purl.org/dc/terms/modified' target='blank'  title='Definition Modified in the Dublin Core Terms Vocabulary'>Modified</a>"
    when "exactMatch"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#exactMatch' target='blank'  title='Definition of exactMatch in the SKOS Vocabulary'>External Exact Match</a>"
    when "closeMatch"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#closeMatch' target='blank'  title='Definition of Modified in the SKOS Vocabulary'>External Close Match</a>"
    when "related"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#related' target='blank'  title='Definition of Related in the SKOS Vocabulary'>Related Terms</a>"
    when "broader"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#broader' target='blank'  title='Definition of Broader in the SKOS Vocabulary'>Broader Terms</a>"
    when "narrower"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#narrower' target='blank'  title='Definition of Narrower in the SKOS Vocabulary'>Narrower Terms</a>"
    when "isReplacedBy"
      "<a class='text-white' href='http://purl.org/dc/terms/isReplacedBy' target='blank'  title='Definition of isReplacedBy in the Dublin Core Terms Vocabulary'>Is Replaced By</a>"
    when "replaces"
      "<a class='text-white' href='http://purl.org/dc/terms/replaces' target='blank'  title='Definition of replaces in the Dublin Core Terms Vocabulary'>Replaces</a>"
    when "historyNote"
      "<a class='text-white' href='http://www.w3.org/2004/02/skos/core#historyNote' target='blank'  title='Definition of historyNote in the SKOS Vocabulary'>History Note</a>"
    when "internalNote"
      "Internal Note (Only Displayed Logged In)"
    when "contributors"
      "<a class='text-white' href='http://purl.org/dc/terms/contributor' target='blank'  title='Definition of contributor in the Dublin Core Terms Vocabulary'>Contributors</a>"
    else
      field.humanize
    end
  end

  # Gets preferred language, preferably in current localization, returns as term_relationship
  def pref_label_localized(lang_id = I18n.locale)
    if self.visibility == "pending"
      tr = self.get_relationships_at_version_release(VersionRelease.pluck(:id)[-1])[Relation::Pref_label].sort_by{|i| i[0] == lang_id ? 0 : 1}[0]
      return TermRelationship.new(term_id: self.id, relation_id: Relation::Pref_label, language_id: tr[0], data: tr[1])
      #return self.get_relationships_at_version_release(VersionRelease.pluck(:id)[-1])
    end
    return self.term_relationships.where(relation_id: Relation::Pref_label).order(Arel.sql("language_id = '#{lang_id.to_s}' DESC"))[0]
  end
  def uri_localized(lang_id = I18n.locale)
    return self.uri.sub('//', "//#{lang_id}.")
  end

  # Get all edits tied to this term (and that it replaces)
  def get_edit_requests
    unless self.edit_requests.count and not self.edit_requests[0].nil?
      return []
    end
    all_edit_requests = [self.edit_requests[-1]]
    while (prev = all_edit_requests[-1].previous)
      all_edit_requests << prev
    end
    return all_edit_requests
  end

  # Get TermRelationship(s) at the point of a specified version release
  def get_relationship_at_version_release(rel_id, vid, lang_id = I18n.locale)
    my_hist = self.get_edit_requests().reverse()
    values = Array.new
    my_hist.each do |er|
      if er.version_release_id > vid
        break
      end
      if rel_id == "identifier" 
        values = er.my_changes[rel_id]
      elsif rel_id == "uri"
        values = er.my_changes[rel_id]
      else
        er.my_changes[rel_id].each do |rc|
          rel_change = [rc[1], rc[2]]
          if rc[0] == "+"
            values << rel_change
          else
            values.delete(rel_change)
          end
        end
      end
    end
    return values
  end
  def get_relationships_at_version_release(vid, lang_id = I18n.locale.to_s)
    values = Relation.all().pluck(:id).map{|rel_id| [rel_id, []]}.to_h
    if vid.nil?
      return values
    end
    if not vid.is_a? Integer
      vid = VersionRelease.find_by(release_identifier: vid).id
    end
    my_hist = self.get_edit_requests().reverse().reject{ |er| er.version_release_id > vid }
    values = Relation.all().pluck(:id).map{|rel_id| [rel_id, []]}.to_h
    my_hist.each do |er|
      Relation.all().pluck(:id).each do |rel_id|
        er.my_changes[rel_id].each do |rc|
          l_id = rc[1]
          rel_change = [l_id, rc[2]]
          if rc[0] == "+"
            values[rel_id] << rel_change
          else
            values[rel_id].delete(rel_change)
          end
        end
        values[rel_id].sort_by!{|i| i[0] == I18n.locale.to_s ? 0 : 1}
      end
      values["identifier"] = er.my_changes["identifier"]
      values["uri"] = er.my_changes["uri"].sub("http:", "https:")
      if lang_id
        values["uri"] = values["uri"].sub('//', "//#{lang_id}.")
      end
    end
    return values
  end
  def get_relationships_at_latest_published_release()
    values = Relation.all().pluck(:id).map{|rel_id| [rel_id, []]}.to_h
    self.term_relationships.pluck(:relation_id, :language_id, :data).map{|rid, lid, d| values[rid] << [lid, d]}
    values["identifier"] = self.identifier
    values["uri"] = self.uri
    return values
  end
  def get_pending_changes
    updated_relationships = get_relationships_at_version_release(self.get_edit_requests.last().id)
    my_changes = Relation.all().pluck(:id).map{|rel_id| [rel_id, []]}.to_h
    Relation.all().pluck(:id).each do |rel_id|
      current_relationships = self.term_relationships.where(relation_id: rel_id).map{|tr| [tr.language_id, tr.data]}.to_set
      updated_relationships = fully_updated_relationships[rel_id].to_set

      (current_relationships - updated_relationships).each do |r|
        my_changes[rel_id] << ["-", r[0], r[1]]
      end
     
    end
    last_er = self.get_edit_requests().reject{|er| er.vote_status == "pending"}.last()
    my_hist = self.get_edit_requests().reverse
    values  = Array.new
    my
  end
  # Get latest published release term was edited in
  def latest_published_release
    published_releases = self.get_edit_requests().reject{|er| er.status != "approved" or er.version_release.status != "Published"}
    return published_releases.empty? ? nil : published_releases[0].version_release
  end

  # Get version release where term was first introduced
  def first_introduced    
    return self.get_edit_requests().last.version_release
  end
  # Returns whether a translation exists for a given language
  # Translation = description, >1 (preferred/alt/normal) label, >1 broader/narrower/related terms
  def translation_exists?(lang_id)
    # Get relationships for this lang and localizations
    lang_ids = Language.where(localizes_language_id: lang_id).pluck(:id) << lang_id
    lang_relationships = self.term_relationships.where(language_id: lang_ids)
    
    lang_desc = lang_relationships.where(relation_id: Relation::Description).count
    lang_labels = lang_relationships.where(relation_id: [Relation::Pref_label, Relation::Label, Relation::Alt_label]).count
    relations = self.term_relationships.where(relation_id: [Relation::Broader, Relation::Narrower, Relation::Related]).count
    return (lang_desc * lang_labels * relations) > 0
    
  end

  def translated_languages
    langs = self.term_relationships.pluck(:language_id).uniq.reject{|x| x.nil?}
    return langs.reject{|l| not translation_exists?(l)}
  end
  
  def show_fields
    attributes.keys - ["id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def terms
    #fields - [:issued, :modified]
    attributes.keys - ["issued", "modified", "identifier", "id", "broader_ids", "narrower_ids", "related_ids"]
  end

  def required? key
    return true if ['prefLabel', 'identifier'].include? key
    return false
  end

  def self.find_with_conditions(q:, rows:, fl:, model:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = "active_fedora_model_ssi:#{model}"
    result = DSolr.find(opts)
    result
  end

  def self.find_solr(q)
    DSolr.find_by_id(q)
  end

  def self.get_terms_from_solr(identifier, limited_terms=nil)
    vocabulary = Vocabulary.find_by(identifier: identifier)
    all_terms = []
    if limited_terms.nil?
      all_terms = Term.find_with_conditions(q:"*:*",
                                            rows: '10000',
                                            fl: 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, topConcept_ssim, isReplacedBy_ssim, replaces_ssim',
                                            model: vocabulary.solr_model)
      all_terms = all_terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
    else
      all_terms = limited_terms
    end
    all_terms
  end


  def self.csv_download(all_terms, version_release, edited_terms=[])
    vocab_id = version_release.vocabulary.id
    string_func = ->(r) { vocab_id >= 4 ? "#{r[1]}@#{r[0]}" : "#{r[1]}" }
    uri_func = ->(r) {"https://homosaurus.org/#{version_release.vocabulary.identifier}/#{Term.find_by(id: r[1].to_i).get_relationship_at_version_release('identifier', version_release.id)}"}
    #if limited_terms.present?
    #all_terms = Term.where(vocabulary_identifier: identifier, visibility: 'visible', identifier: limited_terms).order("lower(pref_label) ASC")
    #else
    #all_terms = Term.where(vocabulary_identifier: identifier, visibility: 'visible').order("lower(pref_label) ASC")
    #end

    #vocabulary = Vocabulary.find_by(identifier: identifier)
    full_graph = []

    all_terms.each do |current_term|

      relationships = current_term.get_relationships_at_version_release(version_release.id, nil)
      
      graph = {}

      base_uri = relationships["uri"]
      graph[:uri] = base_uri
      graph[:identifier] = relationships["identifier"]
      graph[:prefLabel] = relationships[Relation::Pref_label].map{|r| string_func.call(r)}.join("||")

      graph[:other_labels] = relationships[Relation::Label].map{|r| string_func.call(r)}.join("||")
      graph[:altLabel] = relationships[Relation::Alt_label].map{|r| string_func.call(r)}.join("||")
      graph[:description] = relationships[Relation::Description].map{|r| string_func.call(r)}.join("||")
      graph[:historyNote] = relationships[Relation::History_note].map{|r| string_func.call(r)}.join("||")

      graph[:broader] = relationships[Relation::Broader].map{|r| uri_func.call(r)}.join("||")
      graph[:narrower] = relationships[Relation::Narrower].map{|r| uri_func.call(r)}.join("||")
      graph[:related] = relationships[Relation::Related].map{|r| uri_func.call(r)}.join("||")

      graph[:issued] = current_term.created_at.iso8601.split('T').first
      graph[:modified] = current_term.manual_update_date.iso8601.split('T').first

      graph[:isReplacedBy] = relationships[Relation::Replaced_by].map{|r| uri_func.call(r)}.join("||")
      # graph[:isReplacedBy] = []
      # if current_term.is_replaced_by.present?
      #   graph[:isReplacedBy] <<  current_term.is_replaced_by
      # end
      # graph[:isReplacedBy] = graph[:isReplacedBy].join("||")

      graph[:replaces] = []
      if current_term.replaces.present?
        graph[:replaces] <<  current_term.replaces
      end
      graph[:replaces] = graph[:replaces].join("||")

      full_graph << graph
    end

    csv_string = CSV.generate(col_sep: "\t") do |csv|
      cols = ["URI", "identifier", "prefLabel", "prefLabel Alternate Spellings", "altLabel", "description", "historyNote", "broader", "narrower", "related", "issued", "modified", "isReplacedBy", "replaces"]

      csv << cols
      full_graph.each do |term|
        csv << term.values
        pp "========================="
        term.values.each do |v|
          pp v
        end
      end
    end

    csv_string
  end

  def self.all_terms_full_graph(terms, include_lang: true, version_release: nil)
    graph = ::RDF::Graph.new

    terms.each do |current_term|
      current_term.full_graph(graph: graph, include_lang: include_lang, version_release: version_release)
    end
    graph
  end

  def full_graph(graph: nil, include_lang: true, version_release: nil)
    graph = graph.nil? ? ::RDF::Graph.new : graph
    # helper lambdas for backwards compatibility
    string_func = ->(r) { include_lang ? ::RDF::Literal.new(r[1], language: r[0].to_sym) : "#{r[1]}" }
    uri_func = ->(r) {::RDF::URI.new("https://homosaurus.org/#{version_release.vocabulary.identifier}/#{Term.find_by(id: r[1].to_i).get_relationship_at_version_release('identifier', version_release.id)}")}
    uri_func2 = ->(t) {::RDF::URI.new("https://homosaurus.org/#{version_release.vocabulary.identifier}/#{t.get_relationship_at_version_release('identifier', version_release.id)}")}
    base_uri = uri_func2.call(self)
    graph << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    
    # latest_release = self.latest_published_release
    # relationships = self.get_relationships_at_version_release(latest_release.id)
    if version_release.nil?
      relationships = self.get_relationships_at_latest_published_release()
      vocab_id = Vocabulary.last.id
    else
      relationships = self.get_relationships_at_version_release(version_release.id)
      vocab_id = version_release.vocabulary.id
    end

    relationships[Relation::Pref_label].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, string_func.call(r)]
    end
    relationships[Relation::Label].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, string_func.call(r)]
    end

    relationships[Relation::Alt_label].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, string_func.call(r)]
    end
    relationships[Relation::Description].each do |r|
      graph << [base_uri, ::RDF::Vocab::RDFS.comment, string_func.call(r)]
    end
    
    relationships[Relation::Broader].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, uri_func.call(r)]
    end
    relationships[Relation::Narrower].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, uri_func.call(r)]
    end
    relationships[Relation::Related].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.related, uri_func.call(r)]
    end

    relationships[Relation::Lcsh_exact].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{r[1]}")]
    end
    relationships[Relation::Lcsh_close].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{r[1]}")]
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, uri_func2.call(self.get_broadest(version_release.id))]

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.is_replaced_by}")] if self.is_replaced_by.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    graph << [base_uri, ::RDF::Vocab::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::Vocab::DC.modified, ::RDF::Literal.new("#{self.updated_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    
    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("#{self.vocabulary.base_uri}")]
    graph << [base_uri, ::RDF::Vocab::SKOS.changeNote, "Version #{version_release.release_identifier}"]

    graph
  end

  def full_graph_expanded_json(include_lang: true, version_release: nil)
    string_func = ->(r) { include_lang ? {"@language"=>r[0], "@value"=>r[1]} : "#{r[1]}" }
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph = full_graph(include_lang: include_lang, version_release: version_release)
    json_graph = JSON.parse(graph.dump(:jsonld, standard_prefixes: true))
    ["skos:narrower", "skos:broader", "skos:related", "dc:replaces", "dc:isReplacedBy"].each do |r|
      if json_graph[r].nil?
        json_graph[r] = []
      end
      unless json_graph[r].kind_of?(Array)
        json_graph[r] = [json_graph[r]]
      end
      json_graph[r] = json_graph[r].map do |i|
        t = Term.get_from_uri(i["@id"]).get_relationship_at_version_release(Relation::Pref_label, version_release.id)[0]
        {"@id" => i["@id"],
         "skos:prefLabel" => string_func.call(t)
        }
      end
    end
    json_graph.to_json
  end

  def xml_basic(version_release: nil)
    version_release = version_release.nil? ? self.latest_published_release : version_release
    relationships = self.get_relationships_at_version_release(version_release.id)
    include_lang = version_release.vocabulary.id >= 4
    uri_func = ->(t) {::RDF::URI.new("https://homosaurus.org/#{version_release.vocabulary.identifier}/#{t.get_relationship_at_version_release('identifier', version_release.id)}")}
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.record {
        xml.id uri_func.call(self)
        xml.identifier self.identifier
        #xml.prefLabel self.pref_label
        relationships[Relation::Pref_label].each do |r|
          xml.prefLabel(r[1], :language => r[0])
        end

        relationships[Relation::Alt_label].each do |r|
          xml.altLabel(r[1], :language => r[0])
        end

        xml.issued {
          xml.value self.created_at.iso8601.split('T')[0]
          xml.name "xsd:date"
        }
        xml.modified {
          xml.value self.manual_update_date.iso8601.split('T')[0]
          xml.name "xsd:date"
        }

        relationships[Relation::Broader].each do |r|
          rel_term = Term.find_by(id: r[1])
          pflb = rel_term.pref_label_localized()
          xml.broader {
            xml.id uri_func.call(rel_term)
            xml.prefLabel(pflb.data, :language => pflb.language_id)
          }
        end

        relationships[Relation::Narrower].each do |r|
          rel_term = Term.find_by(id: r[1])
          pflb = rel_term.pref_label_localized()
          xml.narrower {
            xml.id uri_func.call(rel_term)
            xml.prefLabel(pflb.data, :language => pflb.language_id)
          }
        end

        relationships[Relation::Related].each do |r|
          rel_term = Term.find_by(id: r[1])
          pflb = rel_term.pref_label_localized()
          xml.related {
            xml.id uri_func.call(rel_term)
            xml.prefLabel(pflb.data, :language => pflb.language_id)
          }
        end
        #xml.comment_ self.description
        relationships[Relation::Description].each do |r|
          xml.comment_(r[1], :language => r[0])
        end
      }
    end

    builder.to_xml
  end

  def marc_basic(version_release: nil)
    xslt  = Nokogiri::XSLT(File.read(Rails.root.join('app', 'assets', 'xslt', 'homosaurus_xml.xsl')))
    xslt.transform(Nokogiri::XML(self.xml_basic(version_release: version_release)))
  end

  def self.xml_basic_for_terms(terms, version_release: nil)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.records do |r|
        terms.each do |term|
          r << term.xml_basic(version_release: version_release).gsub("<?xml version=\"1.0\"?>", "")
        end
      end
    end
    builder.to_xml
  end

  def self.marc_basic_for_terms(terms, version_release: nil)
    xslt  = Nokogiri::XSLT(File.read(Rails.root.join('app', 'assets', 'xslt', 'homosaurus_xml.xsl')))
    xslt.transform(Nokogiri::XML(Term.xml_basic_for_terms(terms, version_release: version_release)))
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/#{self.vocabulary.identifier}/#{self.identifier}"
  end

  def send_solr(vocab=Vocabulary.last)
    DSolr.delete_by_id("homosaurus/#{vocab.identifier}/#{self.identifier}")
    doc = generate_solr_content(vocab, {})
    DSolr.put doc
  end

  def generate_solr_content(vocab=Vocabulary.last, doc={})
    vr = vocab.version_releases.where(status: "Published").last
    trs = self.get_relationships_at_version_release(vr.id)
    latest_release = self.latest_published_release
    
    # FIXME: id prefix fix? Next time.
    doc[:id] = "homosaurus/#{vocab.identifier}/#{self.identifier}"
    doc[:identifier_ssi] = self.identifier
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:model_ssi] = vocab.solr_model
    doc[:has_model_ssim] = [doc[:model_ssi]]
    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:issued_dtsi] = doc[:system_create_dtsi]
    doc[:modified_dtsi] = doc[:system_modified_dtsi]

    doc[:version_ssi] = vocab.version

    doc[:prefLabel_ssim] = trs[Relation::Pref_label].map{|tr| "#{tr[1]}"}
    doc[:prefLabel_tesim] = doc[:prefLabel_ssim]
    doc[:prefLabel_language_ssim] = trs[Relation::Pref_label].map{|tr| "#{tr[1]}@#{tr[0]}"}
    doc[:broader_uri_ssim] = trs[Relation::Broader].map{|tr| Term.find_by(id: tr[1].to_i).uri}
    doc[:related_uri_ssim] = trs[Relation::Related].map{|tr| Term.find_by(id: tr[1].to_i).uri}
    doc[:narrower_uri_ssim] = trs[Relation::Narrower].map{|tr| Term.find_by(id: tr[1].to_i).uri}

    doc[:broader_ssim] = trs[Relation::Broader].map{|tr| Term.find_by(id: tr[1].to_i).identifier}
    doc[:related_ssim] = trs[Relation::Related].map{|tr| Term.find_by(id: tr[1].to_i).identifier}
    doc[:narrower_ssim] = trs[Relation::Narrower].map{|tr| Term.find_by(id: tr[1].to_i).identifier}

    doc[:closeMatch_ssim] = self.close_match
    doc[:exactMatch_ssim] = self.exact_match
    doc[:isReplacedBy_ssim] = [self.is_replaced_by]
    doc[:replaces_ssim] = [self.replaces]


    #doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:altLabel_tesim] = trs[Relation::Alt_label].map{|tr| "#{tr[1]}"}
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:altLabel_language_ssim] = trs[Relation::Alt_label].map{|tr| "#{tr[1]}@#{tr[0]}"}

    #doc[:description_ssi] = self.description
    doc[:description_tesim] = trs[Relation::Description].map{|tr| "#{tr[1]}@#{tr[0]}"}
    doc[:description_ssim] = doc[:description_tesim]
    
    doc[:languageLabel_ssim] = trs[Relation::Label].map{|tr| "#{tr[1]}@#{tr[0]}"}

    doc[:exactMatch_ssim] = self.exact_match.dup
    doc[:closeMatch_ssim] = self.close_match.dup

    doc[:dta_homosaurus_lcase_prefLabel_ssim] = trs[Relation::Pref_label].map{|tr| "#{tr[1].downcase}"}
    doc[:dta_homosaurus_lcase_altLabel_ssim] = trs[Relation::Alt_label].map{|tr| "#{tr[1].downcase}"}
    
    # doc[:topConcept_ssim] = []
    # doc[:topConcept_ssim] << self.get_broadest(20).uri
    # doc[:topConcept_ssim].uniq!
    # doc[:topConcept_uri_ssim] = self.get_broadest(latest_release.id).uri
    doc[:new_model_ssi] = vocab.solr_model + 'Subject'
    doc[:active_fedora_model_ssi] = vocab.solr_model
    doc[:visibility_ssi] = self.visibility
    doc
  end

  def get_broadest(v_id = nil)
    if v_id.nil?
      broader_id = self.term_relationships.where(relation_id: Relation::Broader).first
      broader_id = broader_id ? broader_id.data : nil;
    else
      broader_id = self.get_relationship_at_version_release(Relation::Broader, v_id)[0]
      broader_id = broader_id ? broader_id[1] : nil
    end
    if broader_id
      return Term.find_by(id: broader_id.to_i).get_broadest(v_id)
    else
      return self
    end
  end

  def set_lcsh_cache_fix
    lcsh_subjects = []
    lcsh_subjects = lcsh_subjects + self.close_match_lcsh
    lcsh_subjects = lcsh_subjects + self.exact_match_lcsh

    lcsh_subjects.each do |val|
      ld = LcshSubjectCache.find_by(uri: val)
      if ld.blank?
        english_label = nil
        default_label = nil
        any_match = nil
        full_alt_term_list = []

        if Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).count > 0
          # Get prefLabel
          Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              if result_statement.object.language == :en
                english_label ||= result_statement.object.value
              elsif result_statement.object.language.blank?
                default_label ||= result_statement.object.value
                full_alt_term_list << result_statement.object.value
              else
                any_match ||= result_statement.object.value
                #FIXME
                full_alt_term_list << result_statement.object.value
              end
            end
          end

          full_alt_term_list -= [default_label] if english_label.blank? && default_label.present?
          full_alt_term_list -= [any_match] if english_label.blank? && default_label.blank? && any_match.present?

          default_label ||= any_match
          english_label ||= default_label

          # Get alt labels
          Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('altLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              full_alt_term_list << result_statement.object.value
            end
          end
          full_alt_term_list.uniq!

          #TODO: Broader? Narrower? Etc?
          ld = LcshSubjectCache.create(uri: val, label: english_label, alt_labels: full_alt_term_list)
        else
          raise "Could not find lcsh for prefLabel for: #{val.to_s}"
        end
      end
    end
  end

  # Remove a term relationship and create/modify an edit request.
  def remove_connection(to_term, rel_id, vid, uid)
    connection = term_relationships.where(relation_id: rel_id).find_by(data: "#{to_term.id}")
    # Check if connection already exists by this VR
    con = self.get_relationship_at_version_release(rel_id, vid)
    unless con.map{|c| c[1].to_i}.include? to_term.id
      return
    end
    # # Skip deleting unlinked turns
    # if connection.nil?
    #   return
    # end
    my_changes = EditRequest::makeChangeHash(visibility, uri, identifier)
    #get the er for the version or create one
    er = nil
    if self.edit_requests.pluck(:version_release_id).include?(vid)
      er = self.edit_requests.find_by(version_release_id: vid)
    else
      er = EditRequest.new(:term_id => id,
                           :created_at => DateTime.now,
                           :version_release_id => vid,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")
    end
    #remove the connection from the top-level er
    if er.my_changes[rel_id].include?(["+", nil, "#{to_term.id}"])
      er.my_changes[rel_id].delete(["+", nil, "#{to_term.id}"])
    else
      er.my_changes[rel_id] << ["-", nil, "#{to_term.id}"]
    end

    er.save
    # Create an ER removing the connection
    er_change = EditRequest.create(:term_id => nil,
                                   :creator_id => uid,
                                   :created_at => DateTime.now,
                                   :version_release_id => nil,
                                   :status => "approved",
                                   :my_changes => EditRequest::makeChangeHash(visibility, uri, identifier),
                                   :parent_id => er.id)
    er_change.my_changes[rel_id] << ["-", nil, "#{to_term.id}"]
    er.save
    er_change.save
  end
  # Remove connection from the history entirely
  def wipe_pending_connection(to_term_id, rel_id, vid)
    self.edit_requests.each do |er|
      er.children.each do |erc|
        if erc.my_changes[rel_id].map{|c| c[2].to_i}.include? to_term_id
          erc.destroy!
        end
      end
      if er.my_changes[rel_id].map{|c| c[2].to_i}.include? to_term_id
        new_changes = er.my_changes.clone
        new_changes[rel_id] = new_changes[rel_id].select{|c| c[2].to_i != to_term_id}
        er.update(my_changes: new_changes)
        er.save!
      end
      if er.children.count == 0
        er.destroy!
      end
    end
  end

  def add_connection(to_term, rel_id, vid, uid)
    connection = term_relationships.where(relation_id: rel_id).find_by(data: "#{to_term.id}")
    # Check if connection already exists by this VR
    con = self.get_relationship_at_version_release(rel_id, vid)
    if con.map{|c| c[1].to_i}.include? to_term.id
      return
    end
    my_changes = EditRequest::makeChangeHash(visibility, uri, identifier)
    #get the er for the version or create one
    er = nil
    if self.edit_requests.pluck(:version_release_id).include?(vid)
      er = self.edit_requests.find_by(version_release_id: vid)
      #er.update(status: "approved")
    else
      er = EditRequest.new(:term_id => id,
                           :created_at => DateTime.now,
                           :version_release_id => vid,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")
    end
    #add the connection from the top-level er
    if er.my_changes[rel_id].include?(["-", nil, "#{to_term.id}"])
      er.my_changes[rel_id].delete(["-", nil, "#{to_term.id}"])
    end
    unless er.my_changes[rel_id].include?(["+", nil, "#{to_term.id}"])
      er.my_changes[rel_id] << ["+", nil, "#{to_term.id}"]
    end

    er.save
    # Create an ER adding the connection
    er_change = EditRequest.create(:term_id => nil,
                                   :creator_id => uid,
                                   :created_at => DateTime.now,
                                   :version_release_id => nil,
                                   :status => "approved",
                                   :my_changes => EditRequest::makeChangeHash(visibility, uri, identifier),
                                   :parent_id => er.id)
    er_change.my_changes[rel_id] << ["+", nil, "#{to_term.id}"]
    er.save
    er_change.save
  end

  # Remove links on redirect/deletion for a given version
  def clear_relations(vid, uid, pending=false)
    trs = self.get_relationships_at_version_release(vid)
    [Relation::Broader, Relation::Narrower, Relation::Related].each do |r|
      trs[r].each do |tr|
        if pending
          Term.find_by(id: tr[1].to_i).wipe_pending_connection(self.id, Relation.inverse(r), vid)
        else
          Term.find_by(id: tr[1].to_i).remove_connection(self, Relation.inverse(r), vid, uid)
        end
      end
    end
  end
  # Add links on publishing of version
  def add_relations(vid, uid)
    trs = self.get_relationships_at_version_release(vid)
    [Relation::Broader, Relation::Narrower, Relation::Related].each do |r|
      trs[r].each do |tr|
        Term.find_by(id: tr[1].to_i).add_connection(self, Relation.inverse(r), vid, uid)
      end
    end
  end

  # Redirect this term to another, creating edit request
  def redirect_term(to_term, vid, uid)
    
    #get the er for the version or create one
    er = nil
    if self.edit_requests.pluck(:version_release_id).include?(vid)
      er = self.edit_requests.find_by(version_release_id: vid)
    else
      my_changes = EditRequest::makeChangeHash(visibility, to_term.uri, to_term.identifier)
      er = EditRequest.new(:term_id => self.id,
                           :created_at => DateTime.now,
                           :version_release_id => vid,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")
    end
    #remove the connection if
    er.my_changes[Relation::Redirects_to] = [["+", nil, "#{to_term.id}"]]

    er.save
    er_change = EditRequest.create(:term_id => nil,
                                   :creator_id => uid,
                                   :created_at => DateTime.now,
                                   :version_release_id => nil,
                                   :status => "approved",
                                   :my_changes => EditRequest::makeChangeHash(visibility, to_term.uri, to_term.identifier),
                                   :parent_id => er.id)
    er_change.my_changes[Relation::Redirects_to] = [["+", nil, "#{to_term.id}"]]

    er_change.save
    er.save

    self.clear_relations(vid, uid)

  end
end

