class VocabsController < ApplicationController

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @terms = HomosaurusSubject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first }

    respond_to do |format|
      format.html
      format.nt { render body: HomosaurusSubject.all_terms_full_graph.dump(:ntriples), :content_type => Mime::NT }
      format.jsonld { render body: HomosaurusSubject.all_terms_full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
      format.ttl { render body: HomosaurusSubject.all_terms_full_graph.dump(:ttl, standard_prefixes: true), :content_type => Mime::TTL }
    end
  end

  def show
    @homosaurus = HomosaurusSubject.find('homosaurus/terms/' + params[:id])
    @homosaurus_obj = HomosaurusSubject.find_by(identifier: params[:id])


    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus_obj.full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: @homosaurus_obj.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: @homosaurus_obj.full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end

end
