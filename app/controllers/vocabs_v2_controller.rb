class VocabsV2Controller < ApplicationController

  def index
    #@terms = Homosaurus.all.sort_by { |term| term.preferred_label }
    #@terms = Homosaurus.all
    @terms = HomosaurusV2Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }

    respond_to do |format|
      format.html
      format.nt { render body: HomosaurusV2Subject.all_terms_full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: HomosaurusV2Subject.all_terms_full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: HomosaurusV2Subject.all_terms_full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data HomosaurusV2Subject.csv_download, filename: "HomosaurusV2_#{Date.today}.csv" }
    end
  end

  def show
    @homosaurus = HomosaurusV2Subject.find('homosaurus/v2/' + params[:id])
    @homosaurus_obj = HomosaurusV2Subject.find_by(identifier: params[:id])


    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus_obj.full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: @homosaurus_obj.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: @homosaurus_obj.full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end

end
