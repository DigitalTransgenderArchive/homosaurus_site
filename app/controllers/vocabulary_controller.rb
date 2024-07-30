class VocabularyController < ApplicationController
  before_action :verify_permission, :only => [:new, :edit, :discussion, :post_comment, :post_reply, :edit_comment, :approve_release, :create, :update, :destroy, :replace, :restore, :destroy_version] # ,  :update_immediate
  # Show the index for a vocabulary
  def index
    identifier = params[:id]
    #@vocabulary = Vocabulary.find_by(identifier: identifier)
    #@terms = Term.find_with_conditions(@vocabulary.solr_model, q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    #@terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }

    display_mode = params[:display_mode]
    display_mode ||= "visible"

    @terms = Term.where(vocabulary_identifier: identifier, visibility: display_mode).order("lower(pref_label) ASC")


    respond_to do |format|
      format.html
      format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data Term.csv_download(@terms, @edited_terms), filename: "Homosaurus_#{identifier}_#{Date.today}.csv" }
      format.xml { render body: Term.xml_basic_for_terms(@terms), :content_type => 'text/xml' }
      format.marc { render body: Term.marc_basic_for_terms(@terms), :content_type => 'text/xml' }

      format.ntV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end
  # Show a term
  def show
    @homosaurus_obj = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    logger.debug @homosaurus_obj

    # For terms  that are combined / replaced
    if @homosaurus_obj.visibility == "redirect" and @homosaurus_obj.is_replaced_by.present?
      unless request.formats.present? and request.formats[0].present? and request.formats[0].symbol.to_s != "html"
        redirect_to @homosaurus_obj.is_replaced_by and return
      end
    end

    if @homosaurus_obj.visibility == "pending" and not current_user.present?
      redirect_to vocabulary_index_path(id: params[:vocab_id])
    end

    respond_to do |format|
      format.html
      format.nt { render body: @homosaurus_obj.full_graph.dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: @homosaurus_obj.full_graph.dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.json { render body: @homosaurus_obj.full_graph_expanded_json, :content_type => 'application/json' }
      format.ttl { render body: @homosaurus_obj.full_graph.dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.xml { render body: @homosaurus_obj.xml_basic, :content_type => 'text/xml' }
      format.marc { render body: @homosaurus_obj.marc_basic, :content_type => 'text/xml' }

      format.ntV2 { render body: @homosaurus_obj.full_graph(include_lang: false).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: @homosaurus_obj.full_graph(include_lang: false).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: @homosaurus_obj.full_graph(include_lang: false).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end
  # Search for terms
  def search
    @vocabulary_identifier = params[:id]
    @vocabulary = Vocabulary.find_by(identifier: @vocabulary_identifier)
    if params[:q].present?
      opts = {}
      opts[:q] = params[:q]
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      # opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, isReplacedBy_ssim, replaces_ssim'
      opts[:fq] = "active_fedora_model_ssi:#{@vocabulary.solr_model} AND visibility_ssi:visible"
      response = DSolr.find(opts)
      docs = response
      @terms = Term.where(identifier: docs.pluck("identifier_ssi"), visibility: 'visible')

      respond_to do |format|
        format.html
        format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
        format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
        format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      end
    end
  end
  # Show the history of a term (edit requests)
  def history
    @homosaurus_obj = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @homosaurus = Term.find_solr(@homosaurus_obj.identifier)
    @edit_requests = @homosaurus_obj.get_edit_requests()
    logger.debug @edit_requests
    if not current_user.present?
      @edit_requests.reject!{|er| er.version_release.status != "Published" or er.vote_status != "approved"}
    end
    respond_to do |format|
      format.html
    end
  end
  # Show the discussion of either a term or an edit request
  def discussion
    @homosaurus_obj = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @discussion_type = "Term"
    if params[:release_id]
      @vid = VersionRelease.find_by(release_identifier: params[:release_id]).id
      @homosaurus_obj = @homosaurus_obj.edit_requests.find_by(version_release_id: @vid)
      @discussion_type = "EditRequest"
    end
    @comments = @homosaurus_obj.comments.where(replaces_comment_id: nil)#.where(language_id: I18n.locale)
    respond_to do |format|
      format.html
    end
  end
  # Create a new comment
  def post_comment
    parent = nil
    if params["parent_type"] == "Term"
      parent = Term.find_by(id: params["parent"])
    elsif params["parent_type"] == "EditRequest"
      parent = EditRequest.find_by(id: params["parent"])
    else
      parent = Comment.find_by(id: params["parent"])
    end
    is_vote = params["is_vote"] == "true" ? true : false
    @c = Comment.create(user_id: params["user"],
                        subject: params["subject"] || nil,
                        commentable: parent,
                        content: params["content"],
                        is_vote: is_vote,
                        language_id: params["language_id"])
    if @c.get_root_type() == "Term"
      redirect_to vocabulary_term_discussion_path(:anchor => "comment-#{@c.id}")#, format: :html)
    else
      redirect_to edit_request_discussion_path(:anchor => "comment-#{@c.id}")
    end
  end
  # Edit an existing comment
  def edit_comment
    comment = Comment.find_by(id: params['comment_id'])
    is_vote = (params["is_vote"] == "true")
    subject = is_vote ? params['vote-subject'] : params['subject']
    content = params['content']
    notice = "Comment succesfully edited"
    if comment.subject == subject and comment.content == content
      notice = "No changes made."
      @c = comment
    else
      @c = Comment.create(user_id: comment.user.id,
                          subject: subject,
                          commentable: comment.commentable,
                          content: content,
                          is_vote: is_vote,
                          replaces_comment_id: comment.id,
                          language_id: comment.language_id)
      comment.updated_at = Time.now
      comment.save!
    end
    if @c.get_root_type() == "Term"
      redirect_to vocabulary_term_discussion_path(:anchor => "comment-#{comment.id}"), notice: notice
    else
      redirect_to edit_request_discussion_path(:anchor => "comment-#{comment.id}"), notice: notice
    end
  end
  # Approve the changes to a given term in a given release
  def approve_release
    backurl = request.referer
    vr = VersionRelease.find_by(release_identifier: params["release_id"])
    er = Term.find_by(identifier: params["id"]).edit_requests.find_by(version_release_id: vr.id)
    er.update(status: "approved")
    vs = er.vote_statuses.find_by(language_id: I18n.locale)
    if vs.nil?
      vs = VoteStatus.create!(
        :votable => er,
        :reviewer_id => current_user.id,
        :language_id => I18n.locale,
        :status => "approved"
      )
    else
      vs.update(status: "approved")
      vs.update(reviewer_id: current_user.id)
    end
    redirect_to backurl
  end
  # Initialize term creation page
  def new
    @vocab_id = params[:vocab_id]
    @term = Term.new
    @term.identifier = "homoit" + (Term.where("vocabulary_id >= 3").order(:identifier).pluck(:identifier).last.split("homoit")[1].to_i + 1).to_s.to_s.rjust(7, "0")
    term_query = Term.where(vocabulary_identifier: params[:vocab_id]).order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.id] }
    @vr_exists = true
    if VersionRelease.where(status: "Pending").pluck(:id).count == 0
      flash[:error] = "No pending releases"
      @vr_exists = false
    end
    if @vr_exists and not params[:release_id]
      redirect_to vocabulary_term_new_versioned_path(vocab_id: @vocab_id,
                                                     release_id: VersionRelease.where(status:'Pending')[0].release_identifier)
      return
    end
    @release_id_num = @vr_exists ? VersionRelease.find_by(release_identifier: params[:release_id]).id : nil;
    
    @LCSH_types = LcshSubjectCache.pluck(:uri, :label).map{|i| ["#{i[0].split('/')[-1]} (#{i[1]})", i[0]]}
  end
  # Create a new term in a given release
  def create
    @vocab_id = params[:vocab_id]
    @vocabulary = Vocabulary.find_by(identifier: @vocab_id)
    @term = Term.new
    tparams = params[:term]
    identifier = tparams["identifier"]
    @term.numeric_pid = identifier.split("homoit")[1].to_i
    @term.identifier = identifier
    @term.pid = "homosaurus/v3/#{identifier}"
    @term.uri = "https://homosaurus.org/v3/#{identifier}"
    @term.vocabulary_identifier = "v3"
    @term.vocabulary = @vocabulary
    @term.visibility = "pending"
    @term.manual_update_date = Time.now
    @term.pref_label = tparams["relation_#{Relation::Pref_label}"][0]["data"]
    @term.save!
    er = EditRequest.new(:term_id => @term.id,
                         :created_at => DateTime.now,
                         :version_release_id => params[:version_release].to_i,
                         :my_changes => EditRequest::makeChangeHash(@term.visibility, @term.uri, params[:id]),
                         :parent_id => nil, :status => "pending")
    er_change = EditRequest.new(:term_id => nil,
                                :creator_id => current_user.id,
                                :created_at => DateTime.now,
                                :version_release_id => nil,
                                :status => "approved",
                                :my_changes => EditRequest::makeChangeHash(@term.visibility, @term.uri, params[:id]),
                                :parent_id => er.id)
    logger.debug tparams
    tparams.select{|k,v| k.include? "relation_"}.each do |k, v|
      rel_id = k.split("_")[1].to_i
      v.reject{|x| x["data"] == ""}.each do |d|
        c = ["+", d["language_id"] == "" ? nil : d["language_id"], d["data"]]
        er.my_changes[rel_id] << c
        er_change.my_changes[rel_id] << c
      end
    end
    [["identifier", identifier], ["uri", @term.uri], ["visibility", "pending"]].each do |k, v|
      er.my_changes[k] = v
      er_change.my_changes[k] = v
    end
    er.save!
    er_change.parent_id = er.id
    er_change.save!
    @term.save!
    Term.find_by(id: @term.id).add_relations(params[:version_release].to_i, current_user.id)
    redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "HomosaurusV3 pending term created!"
  end
  # Initialize term editing page
  def edit
    @vocab_id = params[:vocab_id]
    @term = Term.find_by(vocabulary_identifier: @vocab_id, identifier: params[:id])
    unless params[:release_id]
      valid_vids = VersionRelease.where(status:'Pending').reject{|vr| vr.edit_requests.find_by(term_id: @term.id) and vr.edit_requests.find_by(term_id: @term.id).status == "approved"}
      redirect_to vocabulary_term_edit_version_path(vocab_id: @vocab_id, id: params[:id],
                                                    release_id: valid_vids[-1].release_identifier)
      return
    end
    @release_id = params[:release_id]
    @release_id_num = VersionRelease.find_by(release_identifier: @release_id).id
    # if @term.pendings.present?
    #   @term = @term.pendings[0]
    # end
    term_query = Term.where(vocabulary_identifier: params[:vocab_id]).order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.id] }
    @LCSH_types = LcshSubjectCache.pluck(:uri, :label).map{|i| ["#{i[0].split('/')[-1]} (#{i[1]})", i[0]]}
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
  # Save edits to term in a given release
  def update
    @term = Term.find_by(vocabulary_identifier: "v3", identifier: params[:id])
    er = nil
    vr_exists = false
    my_changes = EditRequest::makeChangeHash(@term.visibility, @term.uri, params[:id])
    # Use existing ER for VR if it exists, else create new one
    if @term.edit_requests.where(status: "pending").pluck(:version_release_id).include? params[:version_release].to_i
      er = @term.edit_requests.find_by(version_release_id: params[:version_release].to_i)
      vr_exists = true
    else
      er = EditRequest.new(:term_id => @term.id,
                           :created_at => DateTime.now,
                           :version_release_id => params[:version_release].to_i,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")
    end
    er_change = EditRequest.new(:term_id => nil,
                                :creator_id => current_user.id,
                                :created_at => DateTime.now,
                                :version_release_id => nil,
                                :status => "approved",
                                :my_changes => EditRequest::makeChangeHash(@term.visibility, @term.uri, params[:id]),
                                :parent_id => er.id)
    
    changed = false

    # Get the currently pending values and the currently live ones
    all_current_values = @term.get_relationships_at_version_release(params[:version_release].to_i)
    lpr = @term.latest_published_release()
    all_published_values = @term.get_relationships_at_version_release(lpr.nil? ? @term.get_edit_requests().first.version_release_id : lpr.id)

    if vr_exists
      er.my_changes = my_changes
    end
    
    # Loop over the term relationship related paramaters
    params["term"].each do |k, v|
      if k.include? "relation_"
        rel_id = k.split("_")[1].to_i
        
        param_values = v.map { |x| Relation::ValueStruct.new(x["data"], x["language_id"] == "" ? nil : x["language_id"]) }.to_set
        param_values.reject!{|x| x.data == ""}
        param_values ||= Set.new()
        
        published_values = all_published_values[rel_id].map { |x| Relation::ValueStruct.new(x[1], x[0]) }.to_set
        
        #current_values = all_current_values[rel_id].map { |x| Relation::ValueStruct.new(x[1], x[0]) }.to_set
        
        
        added_values = param_values - published_values
        removed_values = published_values - param_values
        
        # Set ER changes
        change_type = "+"
        [added_values, removed_values].each do |values|
          values.each do |v|
            er.addChange(rel_id, [change_type, v.language_id, v.data])
            unless vr_exists
              er_change.addChange(rel_id, [change_type, v.language_id, v.data])
            end
            changed = true
          end
          change_type = "-"
        end
        # If the term has an er in the release, record how this modifies it
        if vr_exists
          current_values = all_current_values[rel_id].map { |x| Relation::ValueStruct.new(x[1], x[0]) }.to_set
          added_values = param_values - current_values
          removed_values = current_values - param_values
          change_type = "+"
          [added_values, removed_values].each do |values|
            values.each do |v|
              er_change.addChange(rel_id, [change_type, v.language_id, v.data])
              changed = true
            end
            change_type = "-"
          end
        end
      end
    end
    
    if changed
      #@term.add_relations(params[:version_release].to_i, current_user.id)
      er.save!
      er_change.update(parent_id: er.id)
      er_change.save!
      er_change.make_linked_changes()
      redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "HomosaurusV3 pending term updated!"
    else
      redirect_to vocabulary_term_edit_path(vocab_id: "v3",  id: @term.identifier), notice: "No changes were made."
    end
    # Legacy code
    if 1 == 0
      # Update to upcoming new term.
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
        @term.sources = params[:term][:sources]
        @term.contributors = params[:term][:contributors]

        @term.update(term_params)
        @term.save!
        redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "HomosaurusV3 pending term updated!"
        # else create version if this is a version or if the pref_label has changed.
      elsif params[:term][:pref_label_language][0] != @term.pref_label_language || (@term.raw_pendings.present? && @term.raw_pendings.size >= 1)
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
          @term.sources = params[:term][:sources]
          @term.contributors = params[:term][:contributors]
          @term.visibility = "pending"

          @term.update(term_params)
        end
        @term.record_pending
        @term.reload

        # Delete any other raw pending object
        if @term.raw_pendings.present? && @term.raw_pendings.size >= 2
          @term.raw_pendings.last.destroy!
          @term.reload
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier, pending_id: @term.raw_pendings.first.id), notice: "HomosaurusV3 pending term updated!"
        else
          redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier, pending_id: @term.raw_pendings.first.id), notice: "HomosaurusV3 term had a pending version added!"
        end
        # minor update only detected.
      else
        self.update_immediate
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
        @term.sources = params[:term][:sources]
        @term.contributors = params[:term][:contributors]

        @term.update(term_params)
        @term.save

        # FIXME: DO THIS BETTER
        if params[:term][:broader].present?
          params[:term][:broader].each do |broader|
            if broader.present?
              broader_object = Term.find_by(uri: broader)
              @term.broader = @term.broader + [broader_object.uri]
              @term.broader.uniq!
              broader_object.narrower = broader_object.narrower + [@term.uri]
              broader_object.narrower.uniq!

              # Alphabeticalize
              # broader_object.narrower = sort_relations(Term.where(uri: broader_object.narrower))
              # End

              broader_object.save
            end
          end
        end

        if params[:term][:narrower].present?
          params[:term][:narrower].each do |narrower|
            if narrower.present?
              narrower_object = Term.find_by(uri: narrower)
              @term.narrower = @term.narrower + [narrower_object.uri]
              @term.narrower.uniq!
              narrower_object.broader = narrower_object.broader + [@term.uri]
              narrower_object.broader.uniq!
              narrower_object.save
            end

          end
        end

        if params[:term][:related].present?
          params[:term][:related].each do |related|
            if related.present?
              related_object = Term.find_by(uri: related)
              @term.related = @term.related + [related_object.uri]
              @term.related.uniq!
              related_object.related = related_object.related + [@term.uri]
              related_object.related.uniq!
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

  def sort_relations(objs)
    return objs.sort_by { |obj| obj.pref_label.downcase }.map { |obj| obj.uri }
  end

  # Mark term as deleted in a given release
  def destroy
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @term.clear_relations(params[:release_id].to_i, current_user.id)
    #get the er for the version or create one
    er = nil
    if @term.edit_requests.pluck(:version_release_id).include?(params[:release_id].to_i)
      er = @term.edit_requests.find_by(version_release_id: params[:release_id].to_i)
    else
      my_changes = EditRequest::makeChangeHash("deleted", @term.uri, @term.identifier)
      er = EditRequest.new(:term_id => @term.id,
                           :created_at => DateTime.now,
                           :version_release_id => params[:release_id].to_i,
                           :my_changes => my_changes,
                           :parent_id => nil,
                           :status => "pending")
    end
    er.my_changes[Relation::Redirects_to] = [["+", nil, "0"]]

    er.save!

    er_change = EditRequest.create(:term_id => nil,
                                   :creator_id => current_user.id,
                                   :created_at => DateTime.now,
                                   :version_release_id => nil,
                                   :status => "approved",
                                   :my_changes => EditRequest::makeChangeHash("deleted", @term.uri, @term.identifier),
                                   :parent_id => er.id)
    er_change.my_changes[Relation::Redirects_to] = [["+", nil, "0"]]

    er_change.save
    er.save
    
    # clear_relations(@term)
    # @term.clear_relations(VersionRelease.pluck(:id)[-1], current_user.id)
    #@term.visibility = "deleted"
    @term.save!
    #@homosaurus.broader = []
    #@homosaurus.narrower = []
    #@homosaurus.related = []

    #@homosaurus.destroy
    #redirect_to homosaurus_v3_index_path, notice: "HomosaurusV3 term was deleted!"
    redirect_to vocabulary_show_path(vocab_id: "v3",  id: @term.identifier), notice: "Term was marked as deleted! Relations were removed from related terms."
  end
  # Delete pending term and associated records
  def destroy_version
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @term.clear_relations(@term.edit_requests[0].version_release_id, current_user.id, true)
    
    @term.edit_requests.each do |er|
      er.children.each do |erc|
        erc.destroy!
      end
      er.destroy!
    end
    @term.destroy!
    redirect_to vocabulary_term_new_path(vocab_id: "v3"), notice: "New term pending version release was removed!"
  end
  # Replace one term with another and create redirect
  def replace
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @term_being_replaced = Term.find_by(id: params[:replacement_id].to_i)
    @vr = VersionRelease.find_by(id: params["vid"].to_i)

    if @term.blank? || @term_being_replaced.blank? || params[:vocab_id] == params[:replacement_id]
      redirect_to vocabulary_index_path(id: "v3"), notice: "Replacement of term failed"
    else

      @term_being_replaced.redirect_term(@term, @vr.id, current_user.id)

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
    params.require(:term).permit(:identifier, :description, :history_note, :internal_note, :exactMatch, :closeMatch)
  end

  def verify_permission
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.contributor?)
      redirect_to root_path
    end
  end

end

