class SearchController < ApplicationController
  def index
    #@terms = Homosaurus.find_with_conditions({q: params[:term], pf: 'prefLabel_tesim',  qf: "prefLabel_tesim altLabel_tesim description_tesim identifier_tesim"}, rows: '10000' )
    #See def find_in_batches(conditions, opts = {}) method in finder_methods in Active Fedora under lib/active_fedora/relation
    if params[:term].present?
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
      SearchController.custom_find_in_batches(params[:term]) do |group|
        group.each { |object|
          @terms << object
        }
      end

      #@terms = Homosaurus.find_with_conditions({q: params[:term], pf: 'prefLabel_tesim',  qf: "prefLabel_tesim altLabel_tesim description_tesim identifier_tesim"}, rows: '10000' )

      @terms = @terms.sort_by { |term| term["prefLabel_tesim"].first }
    end
  end


  def self.custom_find_in_batches(term)
    opts = {}
    opts[:q] = term
    opts[:pf] = 'prefLabel_tesim'
    opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
    opts[:fl] = 'id,prefLabel_tesim,description_tesim,altLabel_tesim'
    opts[:fq] = 'active_fedora_model_ssi:Homosaurus'
    # set default sort to created date ascending
    #opts[:sort] = 'prefLabel_tesim ascending'

    batch_size = 10000

    counter = 0
    loop do
      counter += 1
      response = ActiveFedora::SolrService.instance.conn.paginate counter, batch_size, "select", params: opts
      docs = response["response"]["docs"]
      yield docs
      break unless docs.has_next?
    end
  end
end
