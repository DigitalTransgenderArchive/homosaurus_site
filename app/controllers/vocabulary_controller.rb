class VocabularyController < ApplicationController

  def index
    identifier = params[:id]
    #@vocabulary = Vocabulary.find_by(identifier: identifier)
    #@terms = Term.find_with_conditions(@vocabulary.solr_model, q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    #@terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }

    @terms = Term.where(vocabulary_identifier: identifier, visibility: 'visible').order("lower(pref_label) ASC")

    respond_to do |format|
      format.html
      format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data Term.csv_download(@terms), filename: "Homosaurus_#{identifier}_#{Date.today}.csv" }
    end
  end

  def show
    @homosaurus_obj = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @homosaurus = Term.find(@homosaurus_obj.identifier)

    # For terms  that are combined / replaced
    if @homosaurus_obj.visibility == "redirect" and @homosaurus_obj.is_replaced_by.present?
      redirect_to @homosaurus_obj.is_replaced_by
    end

    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus_obj.full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: @homosaurus_obj.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.json { render body: @homosaurus_obj.full_graph_expanded_json, :content_type => 'application/json' }
      format.ttl { render body: @homosaurus_obj.full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end

  def search
    @vocabulary_identifier = params[:id]
    @vocabulary = Vocabulary.find_by(identifier: @vocabulary_identifier)
    if params[:q].present?
      opts = {}
      opts[:q] = params[:q]
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, isReplacedBy_ssim, replaces_ssim'
      opts[:fq] = "active_fedora_model_ssi:#{@vocabulary.solr_model}"
      response = DSolr.find(opts)
      docs = response
      @terms = Term.where(pid: docs.pluck("id"), visibility: 'visible')

      respond_to do |format|
        format.html
        format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
        format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
        format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      end
    end
  end

end
