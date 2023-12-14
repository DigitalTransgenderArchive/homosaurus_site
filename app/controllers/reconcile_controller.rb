class ReconcileController < ApplicationController
  def index
    json_graph = {}
    json_graph["name"] = "Homosaurus Reconciliation Service API"
    json_graph["identifierSpace"] = "https://homosaurus.org/reconcile"
    json_graph["schemaSpace"] = "https://homosaurus.org/reconcile"
    json_graph["defaultTypes"] = []

    # View
    json_graph["view"] = {}
    json_graph["view"]["url"] = "https://homosaurus.org/v3/{{id}}"
    json_graph["view"]["width"] = 500
    json_graph["view"]["height"] = 350

    # PreView
    json_graph["preview"] = {}
    json_graph["preview"]["url"] = "https://homosaurus.org/v3/{{id}}"
    json_graph["preview"]["width"] = 500
    json_graph["preview"]["height"] = 350

    # Suggest
    json_graph["suggest"] = {}
    json_graph["suggest"]["entity"] = {}
    json_graph["suggest"]["entity"]["service_url"] = "https://homosaurus.org/reconcile"
    json_graph["suggest"]["entity"]["service_path"] = "/suggest"
    json_graph["suggest"]["entity"]["flyout_service_url"] = "https://homosaurus.org/reconcile"
    json_graph["suggest"]["entity"]["flyout_service_path"] = "/notimplemented"

    respond_to do |format|
      format.html { render body: json_graph.to_json, :content_type => 'application/json' }
      format.json { render body: json_graph.to_json, :content_type => 'application/json' }
    end
      # {"name":"Homosaurus-CSV Reconciliation","identifierSpace":"https:\/\/homosaurus-reconcile-csv.glitch.me\/","schemaSpace":"https:\/\/homosaurus-reconcile-csv.glitch.me\/","defaultTypes":[],"view":{"url":"https:\/\/homosaurus-reconcile-csv.glitch.me\/view\/{{id}}"},"preview":{"width":500,"url":"https:\/\/homosaurus-reconcile-csv.glitch.me\/view\/{{id}}","height":350},"suggest":{"entity":{"service_url":"https:\/\/homosaurus-reconcile-csv.glitch.me","service_path":"\/suggest","flyout_service_url":"https:\/\/homosaurus-reconcile-csv.glitch.me","flyout_sercice_path":"\/flyout"}}}
  end

  def suggest
    @vocabulary = Vocabulary.find_by(identifier: "v3")
    prefix = params[:prefix] || "*"
    cursor = params[:cursor] || 0

    opts = {}
    opts[:q] = params[:prefix]
    opts[:pf] = 'prefLabel_tesim'
    opts[:qf] = 'prefLabel_tesim altLabel_tesim identifier_tesim'
    opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, score'
    opts[:fq] = "active_fedora_model_ssi:#{@vocabulary.solr_model} AND visibility_ssi:visible"
    response = DSolr.find(opts)
    docs = response
    @terms = Term.where(pid: docs.pluck("id"), visibility: 'visible')

    json_graph = {}
    json_graph["code"] = "/api/status/ok"
    json_graph["status"] = "200 OK"
    json_graph["result"] = []

    count = 0
    docs.each do |doc|
      if count >= cursor && count < (cursor+20)
        entry = {}
        entry["id"] = doc["identifier_ssi"]
        entry["name"] = doc["prefLabel_tesim"][0]
        entry["score"] = doc["score"]
        entry["description"] = doc["description_tesim"][0]
        json_graph["result"] << entry
      end
      count += 1
    end
    respond_to do |format|
      format.html { render body: json_graph.to_json, :content_type => 'application/json' }
      format.json { render body: json_graph.to_json, :content_type => 'application/json' }
    end
  end

end