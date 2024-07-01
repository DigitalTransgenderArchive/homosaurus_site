class ReconcileController < ApplicationController
  def index
    json_graph = {}
    if params[:queries].blank?
      json_graph["name"] = "Homosaurus Reconciliation Service API"
      json_graph["identifierSpace"] = "https://api.homosaurus.org/reconcile"
      json_graph["schemaSpace"] = "https://api.homosaurus.org/reconcile"
      json_graph["defaultTypes"] = []

      # View
      json_graph["view"] = {}
      json_graph["view"]["url"] = "https://api.homosaurus.org/v3/{{id}}"
      json_graph["view"]["width"] = 500
      json_graph["view"]["height"] = 350

      # PreView
      json_graph["preview"] = {}
      json_graph["preview"]["url"] = "https://api.homosaurus.org/v3/{{id}}"
      json_graph["preview"]["width"] = 500
      json_graph["preview"]["height"] = 350

      # Suggest
      json_graph["suggest"] = {}
      json_graph["suggest"]["entity"] = {}
      json_graph["suggest"]["entity"]["service_url"] = "https://api.homosaurus.org/reconcile"
      json_graph["suggest"]["entity"]["service_path"] = "/suggest"
      json_graph["suggest"]["entity"]["flyout_service_url"] = "https://api.homosaurus.org/reconcile"
      json_graph["suggest"]["entity"]["flyout_service_path"] = "/notimplemented"
    else
      queries_to_process = JSON.parse(params[:queries])
      puts queries_to_process
      vocabulary = Vocabulary.find_by(identifier: "v3")
      opts = {}
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim identifier_tesim otherPrefLabel_tesim'
      opts[:fl] = 'id,identifier_ssi, prefLabel_tesim, altLabel_tesim, description_tesim, otherPrefLabel_tesim, score'
      opts[:fq] = "active_fedora_model_ssi:#{vocabulary.solr_model} AND visibility_ssi:visible"
      queries_to_process.each do |query_key, query_data|
        query_text = query_data["query"]
        query_limit = query_data["limit"] || 20
        opts[:q] = query_text
        puts "query text "
        puts query_text
        response = DSolr.find(opts)
        docs = response #.take(query_limit)
        if docs.present? and docs.length > 0
          take_amount = [docs.length, query_limit].min
          docs = docs.take(take_amount)
        end
        found_terms = Term.where(pid: docs.pluck("id"), visibility: 'visible')
        json_graph[query_key] = {}
        json_graph[query_key]["result"] = []
        docs.each do |doc|
          entry = {}
          entry["id"] = doc["identifier_ssi"]
          doc["prefLabel_tesim"]
          entry["name"] = doc["prefLabel_tesim"][0]
          score = doc["score"] * 4
          score = [score, 99].min
          entry["score"] = score
          entry["type"] = []
          entry["type"] << {name: "homosaurus", id: "homosaurus"}
          entry["match"] = false
          if doc["prefLabel_tesim"][0].downcase == query_text.downcase
            entry["match"] = true
          end
          if doc["altLabel_tesim"].present?
            doc["altLabel_tesim"].each do |alt_label|
              if alt_label.downcase == query_text.downcase
                entry["match"] = true
              end
            end
          end
          if doc["otherPrefLabel_tesim"].present?
            doc["otherPrefLabel_tesim"].each do |alt_label|
              if alt_label.downcase == query_text.downcase
                entry["match"] = true
              end
            end
          end

          json_graph[query_key]["result"] << entry
        end

      end
    end

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