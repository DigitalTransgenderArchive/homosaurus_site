class SearchV3Controller < ApplicationController
  def index
    if params[:q].present?

      @terms = []
      opts = {}
      opts[:q] = params[:q]
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, isReplacedBy_ssim, replaces_ssim'
      opts[:fq] = 'active_fedora_model_ssi:HomosaurusV3'
      response = DSolr.find(opts)
      docs = response
      @terms = docs

      respond_to do |format|
        format.html
        format.nt { render body: HomosaurusV3Subject.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
        format.jsonld { render body: HomosaurusV3Subject.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
        format.ttl { render body: HomosaurusV3Subject.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      end
    end


  end


  def self.custom_find_in_batches(term)
    opts = {}
    opts[:q] = term
    opts[:pf] = 'prefLabel_tesim'
    opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
    opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim'
    opts[:fq] = 'active_fedora_model_ssi:HomosaurusV3'

    batch_size = 10000

    counter = 0
    loop do
      counter += 1
      docs = response["response"]["docs"]
      yield docs
      break unless docs.has_next?
    end
  end
end
