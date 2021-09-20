class VocabsV3Controller < ApplicationController

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @terms = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }

    respond_to do |format|
      format.html
      format.nt { render body: HomosaurusV3Subject.all_terms_full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: HomosaurusV3Subject.all_terms_full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: HomosaurusV3Subject.all_terms_full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data HomosaurusV3Subject.csv_download, filename: "HomosaurusV3_#{Date.today}.csv" }
    end
  end

  def show
    @homosaurus = HomosaurusV3Subject.find('homosaurus/v3/' + params[:id])
    @homosaurus_obj = HomosaurusV3Subject.find_by(identifier: params[:id])


    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus_obj.full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: @homosaurus_obj.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.json { render body: @homosaurus_obj.full_graph_expanded_json, :content_type => 'application/json' }
      format.ttl { render body: @homosaurus_obj.full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end

end
