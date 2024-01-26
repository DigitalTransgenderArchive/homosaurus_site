class Term < ActiveRecord::Base
  include TermAssignments
  include ::Hist::Model

  has_hist associations: {all: {}}
  before_destroy :remove_from_solr
  after_save :send_solr

  belongs_to :vocabulary
  has_many :version_release_term
  has_many :term_relationships
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
      "<a href='http://purl.org/dc/terms/identifier' target='blank' title='Definition of Identifier in the Dublin Core Terms Vocabulary'>Identifier</a>"
    when "prefLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Preferred Label in the SKOS Vocabulary'>Preferred Term</a>"
    when "label"
      "<a href='http://www.w3.org/2004/02/skos/core#prefLabel' target='blank'  title='Definition of Label in the SKOS Vocabulary'>Other Preferred Terms (usually translations)</a>"
    when "altLabel"
      "<a href='http://www.w3.org/2004/02/skos/core#altLabel' target='blank'  title='Definition of Alternative Label in the SKOS Vocabulary'>Alternative Term (Use For)</a>"
    when "description"
      "<a href='http://www.w3.org/2000/01/rdf-schema#comment' target='blank'  title='Definition of Comment in the RDF Schema Vocabulary'>Description (Scope Note)</a>"
    when "issued"
      "<a href='http://purl.org/dc/terms/issued' target='blank'  title='Definition of Issued in the Dublin Core Terms Vocabulary'>Issued (Created)</a>"
    when "modified"
      "<a href='http://purl.org/dc/terms/modified' target='blank'  title='Definition Modified in the Dublin Core Terms Vocabulary'>Modified</a>"
    when "exactMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#exactMatch' target='blank'  title='Definition of exactMatch in the SKOS Vocabulary'>External Exact Match</a>"
    when "closeMatch"
      "<a href='http://www.w3.org/2004/02/skos/core#closeMatch' target='blank'  title='Definition of Modified in the SKOS Vocabulary'>External Close Match</a>"
    when "related"
      "<a href='http://www.w3.org/2004/02/skos/core#related' target='blank'  title='Definition of Related in the SKOS Vocabulary'>Related Terms</a>"
    when "broader"
      "<a href='http://www.w3.org/2004/02/skos/core#broader' target='blank'  title='Definition of Broader in the SKOS Vocabulary'>Broader Terms</a>"
    when "narrower"
      "<a href='http://www.w3.org/2004/02/skos/core#narrower' target='blank'  title='Definition of Narrower in the SKOS Vocabulary'>Narrower Terms</a>"
    when "isReplacedBy"
      "<a href='http://purl.org/dc/terms/isReplacedBy' target='blank'  title='Definition of isReplacedBy in the Dublin Core Terms Vocabulary'>Is Replaced By</a>"
    when "replaces"
      "<a href='http://purl.org/dc/terms/replaces' target='blank'  title='Definition of replaces in the Dublin Core Terms Vocabulary'>Replaces</a>"
    when "historyNote"
      "<a href='http://www.w3.org/2004/02/skos/core#historyNote' target='blank'  title='Definition of historyNote in the SKOS Vocabulary'>History Note</a>"
    when "internalNote"
      "Internal Note (Only Displayed Logged In)"
    when "contributors"
      "<a href='http://purl.org/dc/terms/contributor' target='blank'  title='Definition of contributor in the Dublin Core Terms Vocabulary'>Contributors</a>"
    else
      field.humanize
    end
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

      graph[:narrower] = current_term.narrower
      graph[:narrower] = graph[:narrower].join("||")

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

  def self.all_terms_full_graph(terms)
    graph = ::RDF::Graph.new

    terms.each do |current_term|
      current_term.full_graph(graph)
    end
    graph
  end

  def full_graph(graph=::RDF::Graph.new)
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.pref_label}"]

    # FIXME: Handle these labels better?
    # self.labels.each do |lbl|
    # graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{lbl}"] if lbl.present?
    # end

    self.alt_labels.each do |alt|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
    end

    graph << [base_uri, ::RDF::Vocab::RDFS.comment, "#{self.description}"] if self.description.present?
    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::Vocab::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::Vocab::DC.modified, ::RDF::Literal.new("#{self.manual_update_date.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]

    self.broader.each do |cb|
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("#{cb}")]
    end

    @broadest_terms = []
    get_broadest self.uri
    @broadest_terms.uniq!
    @broadest_terms.each do |broad_term|
      graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new("#{broad_term}")]
    end

    self.narrower.each do |cn|
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("#{cn}")]
    end

    self.related.each do |cr|
      graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("#{cr}")]
    end

    self.exact_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{match}")] if match.present?
    end
    self.close_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{match}")] if match.present?
    end

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.is_replaced_by}")] if self.is_replaced_by.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("#{self.vocabulary.base_uri}")]
    graph
  end

  def self.all_terms_full_graph_v2(terms)
    graph = ::RDF::Graph.new
    concept_statement = RDF::Statement(::RDF::URI.new("#{terms.first.vocabulary.base_uri}"), ::RDF.type, ::RDF::Vocab::SKOS.ConceptScheme)
    graph << concept_statement

    terms.each do |current_term|
      current_term.full_graph_v2(graph, false)
    end
    graph
  end

  def full_graph_v2(graph=::RDF::Graph.new, include_concept_schema=true)
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.pref_label}"]
    if self.pref_label_language.include?('@')
      graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, ::RDF::Literal.new(self.pref_label_language.split('@')[0], language: self.pref_label_language.split('@')[1].to_sym)]
    end

    # FIXME: Handle these labels better?
    self.labels_language.each do |lbl|
      if lbl.include?('@')
        graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, ::RDF::Literal.new(lbl.split('@')[0], language: lbl.split('@')[1].to_sym)]
      end
    end

    self.alt_labels_language.each do |alt|
      if alt.present?
        if alt.include?('@')
          graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, ::RDF::Literal.new(alt.split('@')[0], language: alt.split('@')[1].to_sym)]
        else
          graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"]
        end
      end
    end

    graph << [base_uri, ::RDF::Vocab::RDFS.comment, "#{self.description}"] if self.description.present?
    graph << [base_uri, ::RDF::Vocab::SKOS.historyNote, "#{self.description}"] if self.history_note.present?

    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::Vocab::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::Vocab::DC.modified, ::RDF::Literal.new("#{self.manual_update_date.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]

    self.broader.each do |cb|
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("#{cb}")]
    end

    self.narrower.each do |cn|
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("#{cn}")]
    end

    self.related.each do |cr|
      graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("#{cr}")]
    end

    self.exact_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{match}")] if match.present?
    end
    self.close_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{match}")] if match.present?
    end

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.is_replaced_by}")] if self.is_replaced_by.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    if include_concept_schema
      concept_statement = RDF::Statement(::RDF::URI.new("#{self.vocabulary.base_uri}"), ::RDF.type, ::RDF::Vocab::SKOS.ConceptScheme)
      graph << concept_statement
    end
    #graph << [::RDF::URI.new("#{self.vocabulary.base_uri}"), ::RDF.type, ::RDF::Vocab::SKOS.ConceptScheme]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("#{self.vocabulary.base_uri}")]
    graph
  end

  def full_graph_expanded_json
    base_uri = ::RDF::URI.new("#{self.uri}")
    graph = ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.pref_label}"]
    # FIXME!!!
    # self.labels.each do |lbl|
    # graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.lbl}"] if lbl.present?
    # end
    self.alt_labels.each do |alt|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
    end
    graph << [base_uri, ::RDF::RDFS.comment, "#{self.description}"] if self.description.present?
    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::Vocab::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::Vocab::DC.modified, ::RDF::Literal.new("#{self.manual_update_date.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]

    self.exact_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{match}")] if match.present?
    end
    self.close_match_lcsh.each do |match|
      graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{match}")] if match.present?
    end

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("#{self.vocabulary.base_uri}")]

    json_graph = JSON.parse(graph.dump(:jsonld, standard_prefixes: true))

    if self.is_replaced_by.present?
      replaced_by_term = Term.find_by(uri: self.is_replaced_by)
      if replaced_by_term.present?
        json_graph["dc:isReplacedBy"] ||= []
        json_graph["dc:isReplacedBy"] << [{"@id": "#{self.is_replaced_by}",
                                           "skos:prefLabel":"#{replaced_by_term.pref_label}"}]
      end
    end
    if self.replaces.present?
      replaces_term = Term.find_by(uri: self.replaces)
      if replaces_term.present?
        json_graph["dc:replaces"] ||= []
        json_graph["dc:replaces"] << [{"@id": "#{self.replaces}",
                                       "skos:prefLabel":"#{replaces_term.pref_label}"}]
      end
    end

    self.broader.each do |cb|
      current_broader = Term.find_by(uri: cb)
      if current_broader.present?
        json_graph["skos:broader"] ||= []
        json_graph["skos:broader"] << [{"@id": "#{current_broader.uri}",
                                        "skos:prefLabel":"#{current_broader.pref_label}"}]
      end
    end

    @broadest_terms = []
    get_broadest self.uri
    @broadest_terms.uniq!
    @broadest_terms.each do |broad_term|
      json_graph["skos:hasTopConcept"] ||= []
      broadest_tern = Term.find_by(uri: broad_term)
      json_graph["skos:hasTopConcept"] << [{"@id": "#{broadest_tern.uri}",
                                            "skos:prefLabel":"#{broadest_tern.pref_label}"}]
    end

    self.narrower.each do |cn|
      current_narrower = Term.find_by(uri: cn)
      if current_narrower.present?
        json_graph["skos:narrower"] ||= []
        json_graph["skos:narrower"] << [{"@id": "#{current_narrower.uri}",
                                         "skos:prefLabel":"#{current_narrower.pref_label}"}]
      end
    end

    self.related.each do |cr|
      current_related = Term.find_by(uri: cr)
      if current_related.present?
        json_graph["skos:related"] ||= []
        json_graph["skos:related"] << [{"@id": "#{current_related.uri}",
                                        "skos:prefLabel":"#{current_related.pref_label}"}]
      end
    end

    json_graph.to_json
  end

  def xml_basic
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
        self.broader.each do |cb|
          current_broader = Term.find_by(uri: cb)
          xml.broader {
            xml.id current_broader.uri
            xml.prefLabel current_broader.pref_label
          }
        end

        self.narrower.each do |cb|
          current_narrower = Term.find_by(uri: cb)
          xml.narrower {
            xml.id current_narrower.uri
            xml.prefLabel current_narrower.pref_label
          }
        end

        self.related.each do |cb|
          current_related = Term.find_by(uri: cb)
          xml.related {
            xml.id current_related.uri
            xml.prefLabel current_related.pref_label
          }
        end

        @broadest_terms = []
        get_broadest self.uri
        @broadest_terms.uniq!
        @broadest_terms.each do |broad_term|
          broadest_term = Term.find_by(uri: broad_term)
          xml.hasTopConcept {
            xml.id broadest_term.uri
            xml.prefLabel broadest_term.pref_label
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

    @broadest_terms = []
    get_broadest(self.uri)

    doc[:topConcept_ssim] = []
    @broadest_terms.each do |broadest|
      doc[:topConcept_ssim] << broadest.split('/').last if broadest.present?
    end
    doc[:topConcept_ssim].uniq!
    doc[:topConcept_uri_ssim] = @broadest_terms.uniq if @broadest_terms.present?
    doc[:new_model_ssi] = self.vocabulary.solr_model + 'Subject'
    doc[:active_fedora_model_ssi] = self.vocabulary.solr_model
    doc[:visibility_ssi] = self.visibility
    doc
  end

  def get_broadest(item)
    if Term.find_by(uri: item).broader.blank?
      @broadest_terms << uri
    else
      Term.find_by(uri: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
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
end
