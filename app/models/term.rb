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
  has_many :term_relationships
  has_many :relations, :through => :term_relationships

  has_many :edit_requests

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

  def self.mint(vocab_id: "v3")
    numeric_pid = Term.where(vocabulary_identifier: vocab_id).maximum(:numeric_pid) || 0
    numeric_pid = numeric_pid + 1
    numeric_pid
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
  def get_relationship_at_version_release(rel_id, vid)
    my_hist = self.get_edit_requests().reverse()
    values = Array.new
    my_hist.each do |er|
      if er.version_release_id > vid
        break
      end
      er.my_changes[rel_id].each do |rc|
        rel_change = [rc[1], rc[2]]
        if rc[0] == "+"
          values << rel_change
        else
          values.delete(rel_change)
        end
      end
    end
    return values
  end
  def get_relationships_at_version_release(vid, full_lang = false)
    if not vid.is_a? Integer
      vid = VersionRelease.find_by(release_identifier: vid).id
    end
    my_hist = self.get_edit_requests().reverse().reject{ |er| er.version_release_id > vid }
    values = Relation.all().pluck(:id).map{|rel_id| [rel_id, []]}.to_h
    my_hist.each do |er|
      Relation.all().pluck(:id).each do |rel_id|
        er.my_changes[rel_id].each do |rc|
          lang_id = rc[1].nil? ? nil : (full_lang ? Language.find_by(id: rc[1]).name : rc[1])
          rel_change = [lang_id, rc[2]]
          if rc[0] == "+"
            values[rel_id] << rel_change
          else
            values[rel_id].delete(rel_change)
          end
        end
      end
      values["identifier"] = er.my_changes["identifier"]
      values["uri"] = er.my_changes["uri"]
    end
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
    published_releases = self.get_edit_requests().reject{|er| er.vote_status != "approved" or er.version_release.status != "Published"}
    return published_releases.empty? ? nil : published_releases[0].version_release
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
    # logger.debug("========================================= lol ====================")
    # logger.debug([lang_desc, lang_pref, lang_labels, relations])
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


  def self.csv_download(all_terms)
    #if limited_terms.present?
    #all_terms = Term.where(vocabulary_identifier: identifier, visibility: 'visible', identifier: limited_terms).order("lower(pref_label) ASC")
    #else
    #all_terms = Term.where(vocabulary_identifier: identifier, visibility: 'visible').order("lower(pref_label) ASC")
    #end

    #vocabulary = Vocabulary.find_by(identifier: identifier)
    full_graph = []

    all_terms.each do |current_term|

      relationships = current_term.get_relationships_at_version_release(VersionRelease.where(status: "Published").pluck(:id)[-1])
      
      graph = {}

      base_uri = current_term.uri
      graph[:uri] = base_uri
      graph[:identifier] = current_term.identifier
      graph[:prefLabel] = current_term.pref_label
      graph[:other_labels] = []
      current_term.labels.each do |lbl|
        graph[:other_labels] << lbl
      end
      graph[:other_labels] = graph[:other_labels].join("||")

      graph[:altLabel] = []
      current_term.alt_labels.each do |alt|
        graph[:altLabel] << alt
      end
      graph[:altLabel] = graph[:altLabel].join("||")

      # Note: This can have commas and semicolons
      graph[:description] = current_term.description

      graph[:historyNote] = current_term.history_note

      graph[:broader] = current_term.broader
      graph[:broader] = graph[:broader].join("||")

      #graph[:narrower] = relationships.where()
      graph[:narrower] = relationships[Relation::Narrower].map{|r| Term.find_by(id: r[1].to_i).uri}.join("||")

      # graph[:narrower] = current_term.narrower
      # graph[:narrower] = graph[:narrower].join("||")

      graph[:related] = current_term.related
      graph[:related] = graph[:related].join("||")

      graph[:issued] = current_term.created_at.iso8601.split('T').first
      graph[:modified] = current_term.manual_update_date.iso8601.split('T').first

      graph[:isReplacedBy] = []
      if current_term.is_replaced_by.present?
        graph[:isReplacedBy] <<  current_term.is_replaced_by
      end
      graph[:isReplacedBy] = graph[:isReplacedBy].join("||")

      graph[:replaces] = []
      if current_term.replaces.present?
        graph[:replaces] <<  current_term.replaces
      end
      graph[:replaces] = graph[:replaces].join("||")

      full_graph << graph
    end

    #csv_string = CSV.generate(col_sep: "\t") do |csv|
    csv_string = CSV.generate(col_sep: "\t") do |csv|
      cols = ["URI", "identifier", "prefLabel", "prefLabel Alternate Spellings", "altLabel", "description", "historyNote", "broader", "narrower", "related", "issued", "modified", "isReplacedBy", "replaces"]

      csv << cols
      full_graph.each do |term|
        csv << term.values
      end
    end

    csv_string
  end

  def self.all_terms_full_graph(terms, include_lang: true)
    graph = ::RDF::Graph.new

    terms.each do |current_term|
      current_term.full_graph(graph: graph, include_lang: include_lang)
    end
    graph
  end

  def full_graph(graph: nil, include_lang: true)
    graph = graph.nil? ? ::RDF::Graph.new : graph
    string_func = ->(r) { include_lang ? ::RDF::Literal.new(r[1], language: r[0].to_sym) : "#{r[1]}" }
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    
    latest_release = self.latest_published_release
    relationships = self.get_relationships_at_version_release(latest_release.id)

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
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new(Term.find_by(id: r[1].to_i).uri)]
    end
    relationships[Relation::Narrower].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new(Term.find_by(id: r[1].to_i).uri)]
    end
    relationships[Relation::Related].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new(Term.find_by(id: r[1].to_i).uri)]
    end

    relationships[Relation::Lcsh_exact].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{r[1]}")]
    end
    relationships[Relation::Lcsh_close].each do |r|
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{r[1]}")]
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new(self.get_broadest(latest_release.id).uri)]

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.is_replaced_by}")] if self.is_replaced_by.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    graph << [base_uri, ::RDF::Vocab::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::Vocab::DC.modified, ::RDF::Literal.new("#{self.updated_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    
    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("#{self.vocabulary.base_uri}")]

    graph
  end

  def full_graph_expanded_json
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph = full_graph()
    
    json_graph = JSON.parse(graph.dump(:jsonld, standard_prefixes: true))
    ["skos:narrower", "skos:broader", "skos:related", "dc:replaces", "dc:isReplacedBy"].each do |r|
      if json_graph[r].nil?
        json_graph[r] = []
      end
      unless json_graph[r].kind_of?(Array)
        json_graph[r] = [json_graph[r]]
      end
      json_graph[r].map!{|i| {"@id" => i["@id"], "skos:prefLabel" => Term.find_by(uri: i["@id"]).pref_label}}
    end
    json_graph.to_json
  end

  def xml_basic
    latest_release = self.latest_published_release
    relationships = self.get_relationships_at_version_release(latest_release.id)
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.record {
        xml.id self.uri
        xml.identifier self.identifier
        xml.prefLabel self.pref_label

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
          xml.broader {
            xml.id rel_term.uri
            xml.prefLabel rel_term.pref_label
          }
        end

        relationships[Relation::Narrower].each do |r|
          rel_term = Term.find_by(id: r[1])
          xml.narrower {
            xml.id rel_term.uri
            xml.prefLabel rel_term.pref_label
          }
        end

        relationships[Relation::Related].each do |r|
          rel_term = Term.find_by(id: r[1])
          xml.related {
            xml.id rel_term.uri
            xml.prefLabel rel_term.pref_label
          }
        end
        xml.comment_ self.description
      }
    end

    builder.to_xml
  end

  def marc_basic
    xslt  = Nokogiri::XSLT(File.read(Rails.root.join('app', 'assets', 'xslt', 'homosaurus_xml.xsl')))
    xslt.transform(Nokogiri::XML(self.xml_basic))
  end

  def self.xml_basic_for_terms(terms)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.records do |r|
        terms.each do |term|
          r << term.xml_basic.gsub("<?xml version=\"1.0\"?>", "")
        end
      end
    end
    builder.to_xml
  end

  def self.marc_basic_for_terms(terms)
    xslt  = Nokogiri::XSLT(File.read(Rails.root.join('app', 'assets', 'xslt', 'homosaurus_xml.xsl')))
    xslt.transform(Nokogiri::XML(Term.xml_basic_for_terms(terms)))
  end

  def remove_from_solr
    DSolr.delete_by_id "homosaurus/#{self.vocabulary.identifier}/#{self.identifier}"
  end

  def send_solr
    doc = generate_solr_content
    DSolr.put doc
  end

  def generate_solr_content(doc={})
    # FIXME: id prefix fix? Next time.
    doc[:id] = "homosaurus/#{self.vocabulary.identifier}/#{self.identifier}"
    doc[:system_create_dtsi] = "#{self.created_at.iso8601}"
    doc[:system_modified_dtsi] = "#{self.updated_at.iso8601}"
    doc[:model_ssi] = self.vocabulary.solr_model
    doc[:has_model_ssim] = [doc[:model_ssi]]
    doc[:date_created_tesim] = [self.created_at.iso8601.split('T')[0]]
    doc[:date_created_ssim] = doc[:date_created_tesim]
    doc[:issued_dtsi] = doc[:system_create_dtsi]
    doc[:modified_dtsi] = doc[:system_modified_dtsi]

    doc[:version_ssi] = self.vocabulary.version

    doc[:prefLabel_ssim] = [self.pref_label]
    doc[:prefLabel_tesim] = doc[:prefLabel_ssim]
    doc[:prefLabel_language_ssi] = self.pref_label_language
    doc[:broader_uri_ssim] = self.broader
    doc[:related_uri_ssim] = self.related
    doc[:narrower_uri_ssim] = self.narrower

    doc[:broader_ssim] = []
    self.broader.each do |broader|
      doc[:broader_ssim] << broader.split('/').last
    end

    doc[:related_ssim] = []
    self.related.each do |related|
      doc[:related_ssim] << related.split('/').last
    end

    doc[:narrower_ssim] = []
    self.narrower.each do |narrower|
      doc[:narrower_ssim] << narrower.split('/').last
    end

    doc[:closeMatch_ssim] = self.close_match
    doc[:exactMatch_ssim] = self.exact_match
    doc[:isReplacedBy_ssim] = [self.is_replaced_by]
    doc[:replaces_ssim] = [self.replaces]
    doc[:altLabel_tesim] = self.alt_labels
    doc[:altLabel_ssim] = doc[:altLabel_tesim]
    doc[:altLabel_language_ssim] = self.alt_labels_language
    doc[:identifier_ssi] = self.identifier
    doc[:description_ssi] = self.description
    doc[:description_tesim] = [self.description]
    doc[:languageLabel_ssim] = self.labels_language

    doc[:exactMatch_ssim] = self.exact_match.dup
    doc[:closeMatch_ssim] = self.close_match.dup

    doc[:dta_homosaurus_lcase_prefLabel_ssi] = self.pref_label.downcase
    doc[:dta_homosaurus_lcase_altLabel_ssim] = []
    self.alt_labels.each do |alt|
      doc[:dta_homosaurus_lcase_altLabel_ssim] << alt.downcase if alt.present?
    end

    doc[:topConcept_ssim] = []
    doc[:topConcept_ssim] << self.get_broadest(20)
    doc[:topConcept_ssim].uniq!
    doc[:topConcept_uri_ssim] = @broadest_terms.uniq if @broadest_terms.present?
    doc[:new_model_ssi] = self.vocabulary.solr_model + 'Subject'
    doc[:active_fedora_model_ssi] = self.vocabulary.solr_model
    doc[:visibility_ssi] = self.visibility
    doc
  end

  def get_broadest(v_id)
    broader_id = self.get_relationship_at_version_release(Relation::Broader, v_id)[0]
    if broader_id
      return Term.find_by(id: broader_id[1].to_i).get_broadest(v_id)
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

  def remove_connection(to_term, rel_id, vid)
    connection = term_relationships.where(relation_id: rel_id).find_by(data: to_term.id)
    if connection.nil?
      return
    end
    my_changes = EditRequest::makeChangeHash(visibility, uri, identifier)
    er = EditRequest.new(:term_id => id,
                           :created_at => DateTime.now,
                           :version_release_id => vid,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")

    er_change = EditRequest.new(:term_id => nil,
                                :creator_id => current_user.id,
                                :created_at => DateTime.now,
                                :version_release_id => nil,
                                :status => "approved",
                                :my_changes => EditRequest::makeChangeHash(visibility, uri, identifier),
                                :parent_id => er.id)
  end
end
