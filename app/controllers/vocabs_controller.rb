class VocabsController < ApplicationController

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @terms = Homosaurus.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first }

    respond_to do |format|
      format.html
      format.nt { render body: Homosaurus.all_terms_full_graph.dump(:ntriples), :content_type => Mime::NT }
      format.jsonld { render body: Homosaurus.all_terms_full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
      format.ttl { render body: Homosaurus.all_terms_full_graph.dump(:ttl, standard_prefixes: true), :content_type => Mime::TTL }
    end
  end

  def show
    @homosaurus = Homosaurus.find('homosaurus/terms/' + params[:id])


    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus.full_graph.dump(:ntriples), :content_type => Mime::NT }
      format.jsonld { render body: @homosaurus.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
      format.ttl { render body: @homosaurus.full_graph.dump(:ttl, standard_prefixes: true), :content_type => Mime::TTL }
    end
  end

end
