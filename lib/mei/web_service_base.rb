require 'rest_client'
#require 'restclient/components'
#require 'rack/cache'

module Mei
  module WebServiceBase
    attr_accessor :raw_response

    # mix-in to retreive and parse JSON content from the web
    def get_json(url)
      #RestClient.enable Rack::Cache
      if Settings.homosaurus_config["proxy_host"].present?
        r = RestClient::Request.execute(method: :get, url: url, headers: request_options, proxy: "http://#{Settings.homosaurus_config['proxy_host']}:#{Settings.homosaurus_config['proxy_port']}")
      else
        r = RestClient.get url, request_options
      end

      #RestClient.disable Rack::Cache
      JSON.parse(r)
    end

    def request_options
      { accept: :json }
    end

    def get_xml(url)
      #RestClient.enable Rack::Cache
      r = RestClient.get url
      #RestClient.disable Rack::Cache
      r
    end



  end
end
