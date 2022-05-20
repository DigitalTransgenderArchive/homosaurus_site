class VocabularyController < ApplicationController
  before_action :verify_permission, :only => [:new, :edit, :create, :update, :destroy, :replace, :restore, :destroy_version] # ,  :update_immediate

  def index
    identifier = params[:id]
    #@vocabulary = Vocabulary.find_by(identifier: identifier)
    #@terms = Term.find_with_conditions(@vocabulary.solr_model, q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    #@terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }

    display_mode = params[:display_mode]
    display_mode ||= "visible"

    @terms = Term.where(vocabulary_identifier: identifier, visibility: display_mode).order("lower(pref_label) ASC")
    @edited_terms = Hist::Pending.all

    respond_to do |format|
      format.html
      format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data Term.csv_download(@terms), filename: "Homosaurus_#{identifier}_#{Date.today}.csv" }
      format.ntV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end

  def show
    if params[:pending_id].present?
      pending = Hist::Pending.find(params[:pending_id])
      @homosaurus_obj = pending.reify
    else
      @homosaurus_obj = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    end

    @homosaurus = Term.find_solr(@homosaurus_obj.identifier)

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

      format.ntV2 { render body: @homosaurus_obj.full_graph_v2.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: @homosaurus_obj.full_graph_v2.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: @homosaurus_obj.full_graph_v2.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
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
      opts[:fq] = "active_fedora_model_ssi:#{@vocabulary.solr_model} AND visibility_ssi:visible"
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

  def new
    @vocab_id = params[:vocab_id]
    @term = Term.new
    term_query = Term.where(vocabulary_identifier: params[:vocab_id]).order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.uri] }
  end

  def create
    ActiveRecord::Base.transaction do
      @vocabulary = Vocabulary.find_by(identifier: "v3")
      @term = Term.new
      # Fix the below
      numeric_identifier = Term.mint(vocab_id: "v3")
      identifier = "homoit" + numeric_identifier.to_s.rjust(7, '0')

      @term.numeric_pid = numeric_identifier
      @term.identifier = identifier
      @term.pid = "homosaurus/v3/#{identifier}"
      @term.uri = "https://homosaurus.org/v3/#{identifier}"
      @term.vocabulary_identifier = "v3"
      @term.vocabulary = @vocabulary
      if params[:immediate].present?
        @term.visibility = "visible"
      else
        @term.visibility = "pending"
      end

      @term.manual_update_date = Time.now

      set_match_relationship(params[:term], "exact_match_lcsh")
      set_match_relationship(params[:term], "close_match_lcsh")

      @term.pref_label_language = params[:term][:pref_label_language][0]
      @term.labels_language = params[:term][:labels_language]
      @term.alt_labels_language = params[:term][:alt_labels_language]
      @term.update(term_params)

      @term.save
      if params[:immediate].blank?
        set_match_relationship(params[:term], "broader")
        set_match_relationship(params[:term], "narrower")
        set_match_relationship(params[:term], "related")
      elsif params[:immediate].present?
        if params[:term][:broader].present?
          params[:term][:broader].each do |broader|
            if broader.present?
              #broader = broader.split("(").last[0..-1]
              broader_object = Term.find_by(uri: broader)
              @term.broader = @term.broader + [broader_object.uri]
              broader_object.narrower = broader_object.narrower + [@term.uri]
              broader_object.save
            end
          end
        end

        if params[:term][:narrower].present?
          params[:term][:narrower].each do |narrower|
            if narrower.present?
              #narrower = narrower.split("(").last[0..-1]
              narrower_object = Term.find_by(uri: narrower)
              @term.narrower = @term.narrower + [narrower_object.uri]
              narrower_object.broader = narrower_object.broader + [@term.uri]
              narrower_object.save
            end

          end
        end

        if params[:term][:related].present?
          params[:term][:related].each do |related|
            if related.present?
              #related = related.split("(").last[0..-1]
              related_object = Term.find_by(uri: related)
              @term.related = @term.related + [related_object.uri]
              related_object.related = related_object.related + [@term.uri]
              related_object.save
            end

          end
        end
      end

      if @term.save
        redirect_to vocabulary_show_path(vocab_id: "v3", :id => @term.identifier)
      else
        redirect_to vocabulary_term_new_path(vocab_id: "v3")
      end
    end
  end

  def edit
    @vocab_id = params[:vocab_id]
    @term = Term.find_by(vocabulary_identifier: @vocab_id, identifier: params[:id])
    if @term.pendings.present?
      @term = @term.pendings[0]
    end
    term_query = Term.where(vocabulary_identifier: params[:vocab_id]).order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.uri] }
  end

  def set_match_relationship(form_fields, key)
    form_fields[key.to_sym].each_with_index do |s, index|
      if s.present?
        form_fields[key.to_sym][index] = s.split('(').last
        form_fields[key.to_sym][index].gsub!(/\)$/, '')
      end
    end
    if form_fields[key.to_sym][0].present?
      @term.send("#{key}=", form_fields[key.to_sym].reject { |c| c.empty? })
    elsif @term.send(key).present?
      @term.send("#{key}=", [])
    end
  end

  def update
    if !params[:term][:identifier].match(/^[0-9a-zA-Z_\-+]+$/) || params[:term][:identifier].match(/ /)
      redirect_to vocabulary_show_path(vocab_id: "v3", id: params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else
      @term = Term.find_by(vocabulary_identifier: "v3", identifier: params[:id])
      if @term.visibility == "pending"
        set_match_relationship(params[:term], "exact_match_lcsh")
        set_match_relationship(params[:term], "close_match_lcsh")
        set_match_relationship(params[:term], "broader")
        set_match_relationship(params[:term], "narrower")
        set_match_relationship(params[:term], "related")
        @term.pref_label_language = params[:term][:pref_label_language][0]
        @term.labels_language = params[:term][:labels_language]
        @term.labels_language = params[:term][:labels_language]
        @term.alt_labels_language = params[:term][:alt_labels_language]

        @term.update(term_params)
        @term.save!
        redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "HomosaurusV3 pending term updated!"
      else
        Hist::Pending.start_pending do
          set_match_relationship(params[:term], "exact_match_lcsh")
          set_match_relationship(params[:term], "close_match_lcsh")
          set_match_relationship(params[:term], "broader")
          set_match_relationship(params[:term], "narrower")
          set_match_relationship(params[:term], "related")
          @term.pref_label_language = params[:term][:pref_label_language][0]
          @term.labels_language = params[:term][:labels_language]
          @term.labels_language = params[:term][:labels_language]
          @term.alt_labels_language = params[:term][:alt_labels_language]
          @term.visibility = "pending"

          @term.update(term_params)
        end
        @term.record_pending

        # Delete any other raw pending object
        if @term.raw_pendings.present? && @term.raw_pendings.size >= 2
          @term.raw_pendings.last.destroy!
          @term.reload
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier, pending_id: @term.raw_pendings.first.id), notice: "HomosaurusV3 pending term updated!"
        else
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier, pending_id: @term.raw_pendings.first.id), notice: "HomosaurusV3 term had a pending version added!"
        end


      end

    end

  end

  def publish_single_obj
    @term = Term.find_by(vocabulary_identifier: "v3", identifier: params[:id])
    if @term.visibility != "pending"
      if @term.pendings.present?
        ActiveRecord::Base.transaction do
          pending = Hist::Pending.find(@term.raw_pendings[0].id)
          obj_reified = pending.reify
          obj_reified.save!
          pending.destroy!
          @term.reload
        end
      end
    end


  end

  # FIX the related stuff not needing identifiers for value
  def update_immediate
    if !params[:term][:identifier].match(/^[0-9a-zA-Z_\-+]+$/) || params[:term][:identifier].match(/ /)
      redirect_to vocabulary_show_path(vocab_id: "v3", id: params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else
      ActiveRecord::Base.transaction do
        @term = Term.find_by(vocabulary_identifier: "v3", identifier: params[:id])

        pid = "homosaurus/v3/#{params[:term][:identifier]}"
        pid_original = @term.pid

        #FIXME: Only do this if changed...
        @term.broader.each do |broader|
          #broader = broader.split("(").last[0..-1]
          hier_object = Term.find_by(uri: broader)
          hier_object.narrower.delete(@term.uri)
          hier_object.save
        end


        @term.narrower.each do |narrower|
          #narrower = narrower.split("(").last[0..-1]
          hier_object = Term.find_by(uri: narrower)
          hier_object.broader.delete(@term.uri)
          hier_object.save
        end


        @term.related.each do |related|
          #related = related.split("(").last[0..-1]
          hier_object = Term.find_by(uri: related)
          hier_object.related.delete(@term.uri)
          hier_object.save
        end
        #@term.reload

        @term.broader = []
        @term.narrower = []
        @term.related = []

        @term.pid = pid
        @term.uri = "https://homosaurus.org/v3/#{params[:term][:identifier]}"
        @term.identifier = params[:term][:identifier]

        set_match_relationship(params[:term], "exact_match_lcsh")
        set_match_relationship(params[:term], "close_match_lcsh")

        @term.pref_label_language = params[:term][:pref_label_language][0]
        @term.labels_language = params[:term][:labels_language]
        @term.alt_labels_language = params[:term][:alt_labels_language]

        @term.update(term_params)
        @term.save

        # FIXME: DO THIS BETTER
        if params[:term][:broader].present?
          params[:term][:broader].each do |broader|
            if broader.present?
              broader_object = Term.find_by(uri: broader)
              @term.broader = @term.broader + [broader_object.uri]
              broader_object.narrower = broader_object.narrower + [@term.uri]
              broader_object.save
            end
          end
        end

        if params[:term][:narrower].present?
          params[:term][:narrower].each do |narrower|
            if narrower.present?
              narrower_object = Term.find_by(uri: narrower)
              @term.narrower = @term.narrower + [narrower_object.uri]
              narrower_object.broader = narrower_object.broader + [@term.uri]
              narrower_object.save
            end

          end
        end

        if params[:term][:related].present?
          params[:term][:related].each do |related|
            if related.present?
              related_object = Term.find_by(uri: related)
              @term.related = @term.related + [related_object.uri]
              related_object.related = related_object.related + [@term.uri]
              related_object.save
            end

          end
        end


        if @term.save
          #flash[:success] = "HomosaurusV3 term was updated!"
          if pid != pid_original
            DSolr.delete_by_id(pid_original)
          end
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "HomosaurusV3 term was updated!"
        else
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "Failure! Term was not updated."
        end
      end
    end
  end

  def destroy
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])

    clear_relations(@term)
    @term.visibility = "deleted"
    @term.save!
    #@homosaurus.broader = []
    #@homosaurus.narrower = []
    #@homosaurus.related = []

    #@homosaurus.destroy
    #redirect_to homosaurus_v3_index_path, notice: "HomosaurusV3 term was deleted!"
    redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "Term was marked as deleted! Relations were removed from related terms."
  end

  def destroy_version
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    if @term.raw_pendings.present?
      pending = Hist::Pending.find(@term.raw_pendings[0].id)
      pending.destroy!
      redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "Existing Term pending version release was removed!"
    elsif @term.visibility == "pending"
      @term.destroy!
      redirect_to vocabulary_term_new_path(vocab_id: "v3"), notice: "New term pending version release was removed!"
    end
  end

  def replace
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @term_being_replaced = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:replacement_id])

    if @term.blank? || @term_being_replaced.blank? || params[:vocab_id] == params[:replacement_id]
      redirect_to vocabulary_index_path(id: "v3"), notice: "Replacement of term failed"
    else
      clear_relations(@term_being_replaced)
      @term_being_replaced.is_replaced_by = @term.uri
      @term_being_replaced.visibility = "redirect"
      @term_being_replaced.save!

      redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "The old term of #{@term_being_replaced.uri} should redirect here now."
    end
  end

  def restore
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])

    set_restore_relations(@term)

    @term.visibility = "visible"
    @term.save!

    redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "Term was restored!"
  end

  def clear_relations(term)
    term.broader.each do |broader|
      hier_object = Term.find_by(uri: broader)
      hier_object.narrower.delete(term.uri)
      hier_object.save
    end

    term.narrower.each do |narrower|
      hier_object = Term.find_by(uri: narrower)
      hier_object.broader.delete(term.uri)
      hier_object.save
    end

    term.related.each do |related|
      hier_object = Term.find_by(uri: related)
      hier_object.related.delete(term.uri)
      hier_object.save
    end
  end

  def set_restore_relations(term)
    term.broader.each do |broader|
      hier_object = Term.find_by(uri: broader)
      hier_object.narrower = hier_object.narrower + [term.uri]
      hier_object.save
    end


    term.narrower.each do |narrower|
      hier_object = Term.find_by(uri: narrower)
      hier_object.narrower = hier_object.narrower + [term.uri]
      hier_object.save
    end


    term.related.each do |related|
      hier_object = Term.find_by(uri: related)
      hier_object.narrower = hier_object.narrower + [term.uri]
      hier_object.save
    end
  end

  def term_params
    params.require(:term).permit(:identifier, :description, :history_note, :exactMatch, :closeMatch)
  end

  def verify_permission
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.contributor?)
      redirect_to root_path
    end
  end

end
