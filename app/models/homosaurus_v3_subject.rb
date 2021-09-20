class HomosaurusV3Subject < HomosaurusSubject

  def self.find_with_conditions(q:, rows:, fl:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = 'active_fedora_model_ssi:HomosaurusV3'
    result = DSolr.find(opts)
    result
  end

def self.find(q)
  DSolr.find_by_id(q)
end


def self.csv_download(limited_terms=nil)
  all_terms = []
  if limited_terms.nil?
    all_terms = HomosaurusV3Subject.find_with_conditions(q:"*:*", rows: '10000', fl: 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, topConcept_ssim' )
    all_terms = all_terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
  else
    all_terms = limited_terms
  end

  full_graph = []

  all_terms.each do |current_term|
    graph = {}

    base_uri = "http://homosaurus.org/v3/#{current_term['identifier_ssi']}"
    graph[:uri] = base_uri
    graph[:identifier] = current_term['identifier_ssi']
    graph[:prefLabel] = current_term['prefLabel_tesim'].first
    graph[:engLabel] = '' # needs label_eng
    graph[:altLabel] = []
    if current_term['altLabel_tesim'].present?
      current_term['altLabel_tesim'].each do |alt|
        graph[:altLabel] << alt if alt.present?
      end
    end
    graph[:altLabel] = graph[:altLabel].join("||")

    graph[:description] = current_term['description_tesim'][0]

    graph[:broader] = []
    if current_term['broader_ssim'].present?
      current_term['broader_ssim'].each do |current_broader|
        graph[:broader] << "http://homosaurus.org/v3/#{current_broader.split('/').last}" if current_broader.present?
      end
    end
    graph[:broader] = graph[:broader].join("||")

    graph[:narrower] = []
    if current_term['narrower_ssim'].present?
      current_term['narrower_ssim'].each do |current_narrower|
        graph[:narrower] << "http://homosaurus.org/v3/#{current_narrower.split('/').last}" if current_narrower.present?
      end
    end
    graph[:narrower] = graph[:narrower].join("||")

    graph[:related] = []
    if current_term['related_ssim'].present?
      current_term['related_ssim'].each do |current_related|
        graph[:related] << "http://homosaurus.org/v3/#{current_related.split('/').last}" if current_related.present?
      end
    end
    graph[:related] = graph[:related].join("||")

    graph[:topConcept] =  []
    if current_term['topConcept_ssim'].present?
      current_term['topConcept_ssim'].each do |top_concept|
        graph[:topConcept]  << "http://homosaurus.org/v3/#{top_concept}" if top_concept.present?
      end
    end
    graph[:topConcept] = graph[:topConcept].join("||")

    graph[:issued] = current_term['issued_dtsi'].split('T').first
    graph[:modified] = current_term['modified_dtsi'].split('T').first

    graph[:isReplacedBy] =  []
    if current_term['isReplacedBy_ssim'].present?
      current_term['isReplacedBy_ssim'].each do |replaced_by_concept|
        graph[:isReplacedBy]  << replaced_by_concept if replaced_by_concept.present?
      end
    end
    graph[:replaces] =  []
    if current_term['replaces_ssim'].present?
      current_term['replaces_ssim'].each do |replaces_concept|
        graph[:replaces]  << replaces_concept if replaces_concept.present?
      end
    end

    full_graph << graph
  end

  csv_string = CSV.generate do |csv|
    cols = ["URI", "identifier", "prefLabel", "label@eng-us", "altLabel", "comment", "broader", "narrower", "related", "hasTopConcept", "issued", "modified", "isReplacedBy", "replaces"]

    csv << cols
    full_graph.each do |term|
      csv << term.values
    end
  end

  csv_string

end


def self.all_terms_full_graph(limited_terms=nil)
  all_terms = []
  if limited_terms.nil?
    all_terms = HomosaurusV3Subject.find_with_conditions(q:"*:*", rows: '10000', fl: 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, topConcept_ssim' )
    all_terms = all_terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
  else
    all_terms = limited_terms
  end

  graph = ::RDF::Graph.new

  all_terms.each do |current_term|
    base_uri = ::RDF::URI.new("http://homosaurus.org/v3/#{current_term['identifier_ssi']}")
    graph << ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{current_term['identifier_ssi']}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{current_term['prefLabel_tesim'].first}"]
    if current_term['altLabel_tesim'].present?
      current_term['altLabel_tesim'].each do |alt|
        graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
      end
    end

    graph << [base_uri, ::RDF::RDFS.comment, "#{current_term['description_tesim'][0]}"] if current_term['description_tesim'].present? and current_term['description_tesim'][0].present?
    graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{current_term['issued_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{current_term['modified_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]

    if current_term['broader_ssim'].present?
      current_term['broader_ssim'].each do |current_broader|
        graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/v3/#{current_broader.split('/').last}")] if current_broader.present?
      end
    end

    if current_term['narrower_ssim'].present?
      current_term['narrower_ssim'].each do |current_narrower|
        graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/v3/#{current_narrower.split('/').last}")] if current_narrower.present?
      end
    end

    if current_term['related_ssim'].present?
      current_term['related_ssim'].each do |current_related|
        graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/v3/#{current_related.split('/').last}")] if current_related.present?
      end
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{current_term['exactMatch_tesim']}")] if current_term['exactMatch_tesim'].present?
    graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{current_term['closeMatch_tesim']}")] if current_term['closeMatch_tesim'].present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    if current_term['topConcept_ssim'].present?
      current_term['topConcept_ssim'].each do |top_concept|
        graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new("http://homosaurus.org/v3/#{top_concept}")] if top_concept.present?
      end
    end

    if current_term['isReplacedBy_ssim'].present?
      current_term['isReplacedBy_ssim'].each do |current_isReplacedBy|
        graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{current_isReplacedBy}")] if current_isReplacedBy.present?
      end
    end
    if current_term['replaces_ssim'].present?
      current_term['replaces_ssim'].each do |current_replaces|
        graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{current_replaces}")] if current_isReplacedBy.present?
      end
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("http://homosaurus.org/terms")]
  end
  graph
end

  def full_graph
    base_uri = ::RDF::URI.new("http://homosaurus.org/v3/#{self.identifier}")
    graph = ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.label}"]
    self.alt_labels.each do |alt|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
    end
    graph << [base_uri, ::RDF::RDFS.comment, "#{self.description}"] if self.description.present?
    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]

    self.broader.each do |cb|
      current_broader = HomosaurusV3Subject.find_by(identifier: cb)
      graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/v3/#{current_broader.identifier}")] if current_broader.present?
    end

    @broadest_terms = []
    get_broadest self.identifier
    @broadest_terms.each do |broad_term|
      graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new("http://homosaurus.org/v3/#{broad_term}")]
    end

    self.narrower.each do |cn|
      current_narrower = HomosaurusV3Subject.find_by(identifier: cn)
      graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/v3/#{current_narrower.identifier}")] if current_narrower.present?
    end

    self.related.each do |cr|
      current_related = HomosaurusV3Subject.find_by(identifier: cr)
      graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/v3/#{current_related.identifier}")] if current_related.present?
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{self.exactMatch}")] if self.exactMatch.present?
    graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{self.closeMatch}")] if self.closeMatch.present?

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.isReplacedBy}")] if self.isReplacedBy.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("http://homosaurus.org/terms")]
    graph
  end

  def full_graph_expanded_json
    base_uri = ::RDF::URI.new("http://homosaurus.org/v3/#{self.identifier}")
    graph = ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{self.identifier}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{self.label}"]
    self.alt_labels.each do |alt|
      graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
    end
    graph << [base_uri, ::RDF::RDFS.comment, "#{self.description}"] if self.description.present?
    #From: https://github.com/ruby-rdf/rdf/blob/7dd766fe34fe4f960fd3e7539f3ef5d556b25013/lib/rdf/model/literal.rb
    #graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.issued}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    #graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.modified}", datatype: ::RDF::URI.new('https://www.loc.gov/standards/datetime/pre-submission.html'))]
    graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{self.created_at.iso8601.split('T')[0]}", datatype: ::RDF::XSD.date)]

    graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{self.exactMatch}")] if self.exactMatch.present?
    graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{self.closeMatch}")] if self.closeMatch.present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("http://homosaurus.org/terms")]

    graph << [base_uri, ::RDF::Vocab::DC.isReplacedBy, ::RDF::URI.new("#{self.isReplacedBy}")] if self.isReplacedBy.present?
    graph << [base_uri, ::RDF::Vocab::DC.replaces, ::RDF::URI.new("#{self.replaces}")] if self.replaces.present?

    json_graph = JSON.parse(graph.dump(:jsonld, standard_prefixes: true))
    self.broader.each do |cb|
      current_broader = HomosaurusV3Subject.find_by(identifier: cb)
      if current_broader.present?
        json_graph["skos:broader"] ||= []
        json_graph["skos:broader"] << [{"@id": "http://homosaurus.org/v3/#{current_broader.identifier}",
                                      "skos:prefLabel":"#{current_broader.label}"}]
      end
    end

    @broadest_terms = []
    get_broadest self.identifier
    @broadest_terms.uniq!
    @broadest_terms.each do |broad_term|
      json_graph["skos:hasTopConcept"] ||= []
      broadest_label = HomosaurusV3Subject.find_by(identifier: broad_term).label
      json_graph["skos:hasTopConcept"] << [{"@id": "http://homosaurus.org/v3/#{broad_term}",
                                    "skos:prefLabel":"#{broadest_label}"}]
    end

    self.narrower.each do |cn|
      current_narrower = HomosaurusV3Subject.find_by(identifier: cn)
      if current_narrower.present?
        json_graph["skos:narrower"] ||= []
        json_graph["skos:narrower"] << [{"@id": "http://homosaurus.org/v3/#{current_narrower.identifier}",
                                       "skos:prefLabel":"#{current_narrower.label}"}]
      end
    end

    self.related.each do |cr|
      current_related = HomosaurusV3Subject.find_by(identifier: cr)
      if current_related.present?
        json_graph["skos:related"] ||= []
        json_graph["skos:related"] << [{"@id": "http://homosaurus.org/v3/#{current_related.identifier}",
                                       "skos:prefLabel":"#{current_related.label}"}]
      end
    end

    json_graph.to_json
  end

  def get_broadest(item)
    if HomosaurusV3Subject.find_by(identifier: item).broader.blank?
      @broadest_terms << item.split('/').last
    else
      HomosaurusV3Subject.find_by(identifier: item).broader.each do |current_broader|
        get_broadest(current_broader)
      end
    end
  end

end
