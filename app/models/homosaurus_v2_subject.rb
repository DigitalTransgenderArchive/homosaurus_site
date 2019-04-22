class HomosaurusV2Subject < HomosaurusSubject

  def self.find_with_conditions(q:, rows:, fl:)
    opts = {}
    opts[:q] = q
    opts[:fl] = fl
    opts[:rows] = rows
    opts[:fq] = 'active_fedora_model_ssi:HomosaurusV2'
    result = DSolr.find(opts)
    result
  end

def self.find(q)
  DSolr.find_by_id(q)
end



def self.all_terms_full_graph(limited_terms=nil)
  all_terms = []
  if limited_terms.nil?
    all_terms = HomosaurusV2Subject.find_with_conditions(q:"*:*", rows: '10000', fl: 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, topConcept_ssim' )
    all_terms = all_terms.sort_by { |term| term["prefLabel_tesim"].first }
  else
    all_terms = limited_terms
  end

  graph = ::RDF::Graph.new

  all_terms.each do |current_term|
    base_uri = ::RDF::URI.new("http://homosaurus.org/v2/#{current_term['identifier_ssi']}")
    graph << ::RDF::Graph.new << [base_uri, ::RDF::Vocab::DC.identifier, "#{current_term['identifier_ssi']}"]
    graph << [base_uri, ::RDF::Vocab::SKOS.prefLabel, "#{current_term['prefLabel_tesim'].first}"]
    if current_term['altLabel_tesim'].present?
      current_term['altLabel_tesim'].each do |alt|
        graph << [base_uri, ::RDF::Vocab::SKOS.altLabel, "#{alt}"] if alt.present?
      end
    end

    graph << [base_uri, ::RDF::RDFS.comment, "#{current_term['description_tesim']}"] if current_term['description_tesim'].present?
    graph << [base_uri, ::RDF::DC.issued, ::RDF::Literal.new("#{current_term['issued_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]
    graph << [base_uri, ::RDF::DC.modified, ::RDF::Literal.new("#{current_term['modified_dtsi'].split('T').first}", datatype: ::RDF::XSD.date)]

    if current_term['broader_ssim'].present?
      current_term['broader_ssim'].each do |current_broader|
        graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/v2/#{current_broader.split('/').last}")] if current_broader.present?
      end
    end

    if current_term['narrower_ssim'].present?
      current_term['narrower_ssim'].each do |current_narrower|
        graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/v2/#{current_narrower.split('/').last}")] if current_narrower.present?
      end
    end

    if current_term['related_ssim'].present?
      current_term['related_ssim'].each do |current_related|
        graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/v2/#{current_related.split('/').last}")] if current_related.present?
      end
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{current_term['exactMatch_tesim']}")] if current_term['exactMatch_tesim'].present?
    graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{current_term['closeMatch_tesim']}")] if current_term['closeMatch_tesim'].present?

    graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
    if current_term['topConcept_ssim'].present?
      current_term['topConcept_ssim'].each do |top_concept|
        graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new("http://homosaurus.org/v2/#{top_concept}")] if top_concept.present?
      end
    end

    graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("http://homosaurus.org/terms")]
  end
  graph
end

def full_graph
  base_uri = ::RDF::URI.new("http://homosaurus.org/v2/#{self.identifier}")
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
    current_broader = HomosaurusV2Subject.find_by(identifier: cb)
    graph << [base_uri, ::RDF::Vocab::SKOS.broader, ::RDF::URI.new("http://homosaurus.org/v2/#{current_broader.identifier}")] if current_broader.present?
  end

  @broadest_terms = []
  get_broadest self.identifier
  @broadest_terms.each do |broad_term|
    graph << [base_uri, ::RDF::Vocab::SKOS.hasTopConcept, ::RDF::URI.new("http://homosaurus.org/v2/#{broad_term}")]
  end

  self.narrower.each do |cn|
    current_narrower = HomosaurusV2Subject.find_by(identifier: cn)
    graph << [base_uri, ::RDF::Vocab::SKOS.narrower, ::RDF::URI.new("http://homosaurus.org/v2/#{current_narrower.identifier}")] if current_narrower.present?
  end

  self.related.each do |cr|
    current_related = HomosaurusV2Subject.find_by(identifier: cr)
    graph << [base_uri, ::RDF::Vocab::SKOS.related, ::RDF::URI.new("http://homosaurus.org/v2/#{current_related.identifier}")] if current_related.present?
  end

  graph << [base_uri, ::RDF::Vocab::SKOS.exactMatch, ::RDF::URI.new("#{self.exactMatch}")] if self.exactMatch.present?
  graph << [base_uri, ::RDF::Vocab::SKOS.closeMatch, ::RDF::URI.new("#{self.closeMatch}")] if self.closeMatch.present?

  graph << [base_uri, ::RDF.type, ::RDF::Vocab::SKOS.Concept]
  graph << [base_uri, ::RDF::Vocab::SKOS.inScheme, ::RDF::URI.new("http://homosaurus.org/terms")]
  graph
end

def get_broadest(item)
  if HomosaurusV2Subject.find_by(identifier: item).broader.blank?
    @broadest_terms << item.split('/').last
  else
    HomosaurusV2Subject.find_by(identifier: item).broader.each do |current_broader|
      get_broadest(current_broader)
    end
  end
end


end
