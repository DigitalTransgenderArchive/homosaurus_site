class ReconcileController < ApplicationController
  def index
    json_graph = {}
    json_graph["name"] = "Homosaurus Reconciliation Service API"
    json_graph["identifierSpace"] = "https://api.homosaurus.org/reconcile"
    json_graph["schemaSpace"] = "https://api.homosaurus.org/reconcile"
    json_graph["defaultTypes"] = []

    # View
    json_graph["view"] = {}
    json_graph["view"]["url"] = "https://homosaurus.org/{{id}}"
    json_graph["view"]["width"] = 500
    json_graph["view"]["height"] = 350

    # PreView
    json_graph["preview"] = {}
    json_graph["preview"]["url"] = "https://homosaurus.org/{{id}}"
    json_graph["preview"]["width"] = 500
    json_graph["preview"]["height"] = 350

    # Suggest
    json_graph["suggest"] = {}
    json_graph["suggest"]["entity"] = {}
    json_graph["suggest"]["entity"]["service_url"] = "https://api.homosaurus.org/reconcile"
    json_graph["suggest"]["entity"]["service_path"] = "/suggest"
    json_graph["suggest"]["entity"]["flyout_service_url"] = "https://api.homosaurus.org/reconcile"
    json_graph["suggest"]["entity"]["flyout_service_path"] = "/flyout"

    respond_to do |format|
      format.html { render body: json_graph.to_json, :content_type => 'application/json' }
      format.json { render body: json_graph.to_json, :content_type => 'application/json' }
    end
      # {"name":"Homosaurus-CSV Reconciliation","identifierSpace":"https:\/\/homosaurus-reconcile-csv.glitch.me\/","schemaSpace":"https:\/\/homosaurus-reconcile-csv.glitch.me\/","defaultTypes":[],"view":{"url":"https:\/\/homosaurus-reconcile-csv.glitch.me\/view\/{{id}}"},"preview":{"width":500,"url":"https:\/\/homosaurus-reconcile-csv.glitch.me\/view\/{{id}}","height":350},"suggest":{"entity":{"service_url":"https:\/\/homosaurus-reconcile-csv.glitch.me","service_path":"\/suggest","flyout_service_url":"https:\/\/homosaurus-reconcile-csv.glitch.me","flyout_sercice_path":"\/flyout"}}}
  end
end