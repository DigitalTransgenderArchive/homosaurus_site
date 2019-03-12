class SearchController < ApplicationController
  def index
    #@terms = Homosaurus.find_with_conditions({q: params[:term], pf: 'prefLabel_tesim',  qf: "prefLabel_tesim altLabel_tesim description_tesim identifier_tesim"}, rows: '10000' )
    #See def find_in_batches(conditions, opts = {}) method in finder_methods in Active Fedora under lib/active_fedora/relation
    if params[:q].present?
=begin
      opts = {}
      opts[:q] = params[:term]
      opts[:pf] = 'prefLabel_tesim'
      # set default sort to created date ascending
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      response = ActiveFedora::SolrService.instance.conn.paginate 0, 100000, "select", params: opts
      @terms = response["response"]["docs"]
=end


      @terms = []
      opts = {}
      opts[:q] = params[:q]
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim'
      opts[:fq] = 'active_fedora_model_ssi:Homosaurus'
      response = DSolr.find(opts)
      docs = response
      @terms = docs

      #SearchController.custom_find_in_batches(params[:q]) do |group|
        #group.each { |object|
          #@terms << object
        #}
      #end

      #@terms = @terms.sort_by { |term| term["prefLabel_tesim"].first }

      respond_to do |format|
        format.html
        format.nt { render body: Homosaurus.all_terms_full_graph(@terms).dump(:ntriples), :content_type => Mime::NT }
        format.jsonld { render body: Homosaurus.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => Mime::JSONLD }
        format.ttl { render body: Homosaurus.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => Mime::TTL }
      end
    end


  end


  def self.custom_find_in_batches(term)
    opts = {}
    opts[:q] = term
    opts[:pf] = 'prefLabel_tesim'
    opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
    opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim'
    opts[:fq] = 'active_fedora_model_ssi:Homosaurus'


    # set default sort to created date ascending
    #opts[:sort] = 'prefLabel_tesim ascending'

    batch_size = 10000

    counter = 0
    loop do
      counter += 1
      #response = ActiveFedora::SolrService.instance.conn.paginate counter, batch_size, "select", params: opts
      docs = response["response"]["docs"]
      yield docs
      break unless docs.has_next?
    end
  end
end
