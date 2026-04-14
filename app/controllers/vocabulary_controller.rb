class VocabularyController < ApplicationController
  
  before_action :verify_suggester_permissions, :only => [:new, :create, :discussion, :post_comment, :post_reply, :edit_comment, :edit, :update, :replace]
  before_action :verify_contrib_permissions, :only => [:destroy, :destroy_version]
  before_action :verify_admin_permissions, :only => [:approve_release, :unapprove_release, :reject_release]
  before_action :verify_super_permissions, :only => [:restore]

  def version_release
    vid = params[:vocab_id]
    vrid = params[:release_id]
    VersionRelease.find_by(identifier: id)
    if Vocabulary.find_by(identifier: vid) and VersionRelease.find_by(release_identifier: vrid)
      render file: "#{Rails.root}/public/static_dumps/#{vid}/#{vrid}.#{params[:format]}"
    end
  end
  # Show the index for a vocabulary
  def index
    identifier = params[:id]
    #@vocabulary = Vocabulary.find_by(identifier: identifier)
    #@terms = Term.find_with_conditions(@vocabulary.solr_model, q: "*:*", rows: '10000', fl: 'id,prefLabel_tesim' )
    #@terms = @terms.sort_by { |term| term["prefLabel_tesim"].first.downcase }
    #@terms = @terms.sort_by{|t| t.pref_label_localized().data}

    display_mode = params[:display_mode]
    display_mode ||= "visible"
    @vocab_identifier = identifier
    @vocab = Vocabulary.find_by(identifier: identifier)

    # Load term identifiers
    @terms = @vocab.terms.where(visibility: display_mode).select(:id, :identifier)
    term_ids = @terms.map(&:id)

    # Load language ids
    lang_id = I18n.locale
    lang_ids = Language.where(localizes_language_id: lang_id).pluck(:id) << lang_id

    # Preload preferred labels
    pref_label_rels = TermRelationship.where(relation_id: Relation::Pref_label).order(Arel.sql("language_id = '#{lang_id.to_s}' DESC")).to_a

    # Store preferred labels
    @pref_label_for = pref_label_rels.group_by(&:term_id).transform_values { |rels| rels.first.data }

    # Sort terms by preferred label
    @terms = @terms.sort_by { |t| (@pref_label_for[t.id]) }

    # If user is logged in
    if current_user.present?
      # Initialize zero counts for each term
      zeroes = term_ids.map { |term| [term, 0] }.to_h

      # Preload counts for each term
      lang_label_counts = zeroes.merge(TermRelationship.where(language_id: lang_ids, relation_id: [Relation::Pref_label, Relation::Label, Relation::Alt_label]).group_by(&:term_id).transform_values { |v| v.count })
      lang_desc_counts = zeroes.merge(TermRelationship.where(language_id: lang_ids, relation_id: Relation::Description).group_by(&:term_id).transform_values { |v| v.count })
      relation_counts = zeroes.merge(TermRelationship.where(relation_id: [Relation::Broader, Relation::Narrower, Relation::Related]).group_by(&:term_id).transform_values { |v| v.count })

      # Store missing translation status
      @translation_exists_for = lang_label_counts.merge(lang_desc_counts, relation_counts) { |k, o, n| o * n }
    end

    latest_published_release = @vocab.version_releases.where(status: "published").last
    path = Rails.root.join("public", "static_dumps", @vocab.identifier, latest_published_release.release_identifier)

    version_release = current_user.present? ?
                        @vocab.version_releases.last :
                        @vocab.latest_published_release()
    
    respond_to do |format|
      format.html
      format.jsonld   { render file: path.to_s + ".jsonld" }
      format.csv      { render file: path.to_s + ".csv" }
      format.nt       { render file: path.to_s + ".nt" }
      format.ttl      { render file: path.to_s + ".ttl" }
      format.xml      { render file: path.to_s + ".xml" }
      format.marc     { render file: path.to_s + ".marc" }

      # Legacy formats
      has_legacy = @vocab.id >= 4 ? ".legacy" : ""
      format.jsonldV2 { render file: path.to_s + has_legacy + ".jsonld" }
      format.ntV2     { render file: path.to_s + has_legacy + ".nt" }
      format.ttlV2    { render file: path.to_s + has_legacy + ".ttl" }

      #format.ntV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false, version_release: version_release).dump(:ntriples), :content_type => "application/n-triples" }
      #format.jsonldV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false, version_release: version_release).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      #format.ttlV2 { render body: Term.all_terms_full_graph(@terms, include_lang: false, version_release: version_release).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end
  # Show a term
  def show
    @vocab_id = params[:vocab_id]
    @vocab = Vocabulary.find_by(identifier: params[:vocab_id])
    @homosaurus_obj = Term.get(params[:vocab_id], params[:id])
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
    # Only include langs V4 and above

    version_release = current_user.present? ?
                        @vocab.version_releases.last :
                        @vocab.latest_published_release()
    
    include_lang = @vocab.id >= 4
    respond_to do |format|
      format.html
      format.nt {
        render body: @homosaurus_obj.full_graph(
                 include_lang: include_lang,
                 version_release: version_release
               ).dump(:ntriples),
               :content_type => "application/n-triples" }
      format.jsonld {
        render body: @homosaurus_obj.full_graph(
                 include_lang: include_lang,
                 version_release: version_release
               ).dump(:jsonld, standard_prefixes: true),
               :content_type => 'application/ld+json' }
      format.json {
        render body: @homosaurus_obj.full_graph_expanded_json(
                 include_lang: include_lang,
                 version_release: version_release),
               :content_type => 'application/json' }
      format.ttl {
        render body: @homosaurus_obj.full_graph(
                 include_lang: include_lang,
                 version_release: version_release
               ).dump(:ttl, standard_prefixes: true),
               :content_type => 'text/turtle' }
      format.xml {
        render body: @homosaurus_obj.xml_basic(version_release: version_release),
               :content_type => 'text/xml' }
      format.marc {
        render body: @homosaurus_obj.marc_basic(version_release: version_release),
               :content_type => 'text/xml' }

      format.ntV2 { render body: @homosaurus_obj.full_graph(include_lang: false, version_release: version_release).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: @homosaurus_obj.full_graph(include_lang: false, version_release: version_release).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: @homosaurus_obj.full_graph(include_lang: false, version_release: version_release).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
    end
  end
  # Search for terms
  def search
    @vocabulary_identifier = params[:id]
    @vocabulary = Vocabulary.find_by(identifier: @vocabulary_identifier)
    include_lang = @vocabulary.id >= 4
    version_release = current_user.present? ?
                        @vocabulary.version_releases.last :
                        @vocabulary.latest_published_release()
    
    if params[:q].present?
      opts = {}
      opts[:q] = params[:q]
      opts[:pf] = 'prefLabel_tesim'
      opts[:qf] = 'prefLabel_tesim altLabel_tesim description_tesim identifier_tesim'
      # opts[:fl] = 'id,identifier_ssi,prefLabel_tesim, altLabel_tesim, description_tesim, issued_dtsi, modified_dtsi, exactMatch_tesim, closeMatch_tesim, broader_ssim, narrower_ssim, related_ssim, isReplacedBy_ssim, replaces_ssim'
      opts[:fq] = "active_fedora_model_ssi:#{@vocabulary.solr_model} AND visibility_ssi:visible"
      opts[:rows] = 50 # max number of results
      response = DSolr.find(opts)
      docs = response
      @terms = Term.where(identifier: docs.pluck("identifier_ssi"), visibility: 'visible')

      respond_to do |format|
        format.html
        format.nt {
          render body: Term.all_terms_full_graph(
                   @terms,
                   include_lang: include_lang,
                   version_release: version_release
                 ).dump(:ntriples),
                 :content_type => "application/n-triples" }
        format.jsonld {
          render body: Term.all_terms_full_graph(
                   @terms,
                   include_lang: include_lang,
                   version_release: version_release
                 ).dump(:jsonld, standard_prefixes: true),
                 :content_type => 'application/ld+json' }
        format.ttl {
          render body: Term.all_terms_full_graph(
                   @terms,
                   include_lang: include_lang,
                   version_release: version_release
                 ).dump(:ttl, standard_prefixes: true),
                 :content_type => 'text/turtle' }
        format.xml {
          render body: Term.all_terms_full_graph(
                   @terms,
                   version_release: version_release),
                 :content_type => 'text/xml' }
        format.marc {
          render body: Term.all_terms_full_graph(
                   @terms,
                   version_release: version_release),
                 :content_type => 'text/xml' }        
          # format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
        # format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
        # format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      end
    end
  end
  # Show the history of a term (edit requests)
  def history
    @homosaurus_obj = Term.get(params[:vocab_id], params[:id])
    @vocab_id = params[:vocab_id]
    @vocab = Vocabulary.find_by(identifier: @vocab_id)
    @homosaurus = Term.find_solr(@homosaurus_obj.identifier)
    @edit_requests = @homosaurus_obj.get_edit_requests()
    logger.debug @edit_requests
    if not current_user.present?
      @edit_requests.reject!{|er| er.version_release.status != "Published" }
    end
    respond_to do |format|
      format.html
    end
  end
  # Show the discussion of either a term or an edit request
  def discussion
    @homosaurus_obj = Term.get(params[:vocab_id], params[:id])
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
    if is_vote and !current_user.contributor?
      redirect_to vocabulary_term_discussion_path()
    end
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
    er.update!(status: "approved")
    vs = er.vote_statuses.find_by(language_id: I18n.locale)
    if vs.nil?
      vs = VoteStatus.create!(
        :votable => er,
        :reviewer_id => current_user.id,
        :language_id => I18n.locale,
        :status => "approved"
      )
    else
      vs.update!(status: "approved")
      vs.update!(reviewer_id: current_user.id)
    end
    redirect_to backurl
  end

  def unapprove_release
    backurl = request.referer
    vr = VersionRelease.find_by(release_identifier: params["release_id"])
    er = Term.find_by(identifier: params["id"]).edit_requests.find_by(version_release_id: vr.id)
    er.update!(status: "pending")
    vs = er.vote_statuses.find_by(language_id: I18n.locale)
    if vs.nil?
      vs = VoteStatus.create!(
        :votable => er,
        :reviewer_id => current_user.id,
        :language_id => I18n.locale,
        :status => "pending"
      )
    else
      vs.update!(status: "pending")
      vs.update!(reviewer_id: current_user.id)
    end
    redirect_to backurl
  end  

  def reject_release
    backurl = request.referer
    vr = VersionRelease.find_by(release_identifier: params["release_id"])
    er = Term.find_by(identifier: params["id"]).edit_requests.find_by(version_release_id: vr.id)
    er.update!(status: "rejected")
    vs = er.vote_statuses.find_by(language_id: I18n.locale)
    if vs.nil?
      vs = VoteStatus.create!(
        :votable => er,
        :reviewer_id => current_user.id,
        :language_id => I18n.locale,
        :status => "rejected"
      )
    else
      vs.update!(status: "rejected")
      vs.update!(reviewer_id: current_user.id)
    end
    redirect_to backurl
  end
  
  # Initialize term creation page
  def new
    @vocab_id = params[:vocab_id]
    @term = Term.new
    @term.identifier = "homoit" + (Term.where("vocabulary_id >= 3").order(:identifier).pluck(:identifier).last.split("homoit")[1].to_i + 1).to_s.to_s.rjust(7, "0")
    term_query = Vocabulary.find_by(identifier: params[:vocab_id]).terms.order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.id] }
    @vr_exists = true
    if VersionRelease.where(status: "Pending").pluck(:id).count == 0
      flash[:error] = "No pending releases"
      @vr_exists = false
    end
    if @vr_exists and not params[:release_id]
      redirect_to vocabulary_term_new_versioned_path(vocab_id: @vocab_id,
                                                     release_id: VersionRelease.where(vocabulary_identifier: @vocab_id, status:'Pending')[0].release_identifier)
      return
    end
    @release_id_num = @vr_exists ? VersionRelease.find_by(release_identifier: params[:release_id]).id : nil;
    
    @LCSH_types = [["Cache uncached term +", -1]] + LcshSubjectCache.pluck(:uri, :label).map{|i| ["#{i[0].split('/')[-1]} (#{i[1]})", i[0]]}
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
    @term.pid = "homosaurus/#{@vocab_id}/#{identifier}"
    @term.uri = "https://homosaurus.org/#{@vocab_id}/#{identifier}"
    @term.vocabulary_identifier = @vocab_id
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
    redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "HomosaurusV3 pending term created!"
  end
  # Initialize term editing page
  def edit
    @vocab_id = params[:vocab_id]
    @term = Term.find_by(identifier: params[:id])
    unless params[:release_id]
      # See if there's a current version
      current_pending_version = VersionRelease.where(status:'Pending').select{|vr| vr.edit_requests.find_by(term_id: @term.id)}
      current_pending_version = current_pending_version.count > 0 ? current_pending_version[0] : nil
      # Find pending VIDS that have not yet been approved
      valid_vids = VersionRelease.where(status:'Pending').reject{|vr|
        vr.edit_requests.find_by(term_id: @term.id) and
          vr.edit_requests.find_by(term_id: @term.id).status == "approved"}
      redirect_id = (current_pending_version ? current_pending_version : valid_vids[0]).release_identifier
      redirect_to vocabulary_term_edit_version_path(vocab_id: @vocab_id, id: params[:id],
                                                    release_id: redirect_id)
      return
    end
    @release_id = params[:release_id]
    @release_id_num = VersionRelease.find_by(release_identifier: @release_id).id
    # if @term.pendings.present?
    #   @term = @term.pendings[0]
    # end
    term_query = Vocabulary.find_by(identifier: params[:vocab_id]).terms.order("lower(pref_label) ASC")
    @all_terms = []
    term_query.each { |term| @all_terms << [term.identifier + " (" + term.pref_label + ")", term.id] }
    @LCSH_types = [["Cache uncached term +", -1]] + LcshSubjectCache.pluck(:uri, :label).map{|i| ["#{i[0].split('/')[-1]} (#{i[1]})", i[0]]}
  end
  # Add new term to LCSH cache and return it
  def add_new_LCSH
    res = LcshSubjectCache::add_new(params["uri"])
    return render json: {value: res[1], text: res[0]}
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
    @term = Term.get(params[:vocab_id], params[:id])
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
    # Create new sub ER for user in VR ER
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
    all_published_values = @term.get_relationships_at_version_release(lpr.nil? ? nil : lpr.id)

    # Loop over the term relationship related paramaters
    params["term"].each do |k, v|
      if k.include? "relation_"
        rel_id = k.split("_")[1].to_i

        # Get the updated values 
        param_values = v.map { |x| Relation::ValueStruct.new(x["data"], x["language_id"] == "" ? nil : x["language_id"]) }.to_set
        param_values.reject!{|x| x.data == ""}
        param_values ||= Set.new()

        # Get the currently published values 
        published_values = all_published_values[rel_id].map { |x| Relation::ValueStruct.new(x[1], x[0]) }.to_set

        # Calculate added/removed values
        added_values = param_values - published_values
        removed_values = published_values - param_values

        # Set VR level ER to diff between submitted params and published values, record if changed
        changes = removed_values.to_a.map{|v| ["-", v.language_id, v.data]} + added_values.to_a.map{|v| ["+", v.language_id, v.data]}
        loc_changes = er.my_changes
        loc_changes[rel_id] = changes
        er.update!(my_changes: loc_changes)
        # If this is creating a VR level ER, copy values
        unless vr_exists
          er_change.update!(my_changes: loc_changes)
          changed = true
        end
        # If this is modifying a pending VR level ER, record how user modified it
        if vr_exists
          current_values = all_current_values[rel_id].map { |x| Relation::ValueStruct.new(x[1], x[0]) }.to_set
          added_values = param_values - current_values
          removed_values = current_values - param_values

          if (added_values + removed_values).count > 0
            changes = removed_values.to_a.map{|v| ["-", v.language_id, v.data]} + added_values.to_a.map{|v| ["+", v.language_id, v.data]}
            loc_changes = er_change.my_changes
            loc_changes[rel_id] = changes
            er_change.update!(my_changes: loc_changes)
            changed = true
          end
        end
      end
    end
    
    if changed
      #@term.add_relations(params[:version_release].to_i, current_user.id)
      er.save!
      er_change.update!(parent_id: er.id)
      er_change.save!
      er_change.make_linked_changes()
      redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "HomosaurusV3 pending term updated!"
    else
      redirect_to vocabulary_term_edit_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "No changes were made."
    end
  end

  def publish_single_obj
    @term = Term.get(params[:vocab_id], params[:id])
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
      redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest, id: params[:id]), notice: "Please use camel case for identifier like 'discrimationWithAbleism'... do not use spaces. Contact K.J. if this is seen for some other valid entry."
    else
      ActiveRecord::Base.transaction do
        @term = Term.find_by(vocabulary_identifier: Vocabulary.latest, identifier: params[:id])

        pid = "homosaurus/#{Vocabulary.latest}/#{params[:term][:identifier]}"
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
        @term.uri = "https://homosaurus.org/#{Vocabulary.latest}/#{params[:term][:identifier]}"
        @term.identifier = params[:term][:identifier]

        set_match_relationship(params[:term], "exact_match_lcsh")
        set_match_relationship(params[:term], "close_match_lcsh")

        @term.pref_label_language = params[:term][:pref_label_language][0]
        @term.labels_language = params[:term][:labels_language]
        @term.alt_labels_language = params[:term][:alt_labels_language]
        @term.sources = params[:term][:sources]
        @term.contributors = params[:term][:contributors]

        @term.update!(term_params)
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
          redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "HomosaurusV3 term was updated!"
        else
          redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "Failure! Term was not updated."
        end
      end
    end
  end

  def sort_relations(objs)
    return objs.sort_by { |obj| obj.pref_label.downcase }.map { |obj| obj.uri }
  end

  # Mark term as deleted in a given release
  def destroy
    @term = Term.get(params[:vocab_id], params[:id])
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
    redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "Term was marked as deleted! Relations were removed from related terms."
  end
  # Delete pending term and associated records
  def destroy_version
    @term = Term.get(params[:vocab_id], params[:id])
    @term = Term.find_by(vocabulary_identifier: params[:vocab_id], identifier: params[:id])
    @term.clear_relations(@term.edit_requests[0].version_release_id, current_user.id, true)
    
    @term.edit_requests.each do |er|
      er.children.each do |erc|
        erc.destroy!
      end
      er.destroy!
    end
    @term.destroy!
    redirect_to vocabulary_term_new_path(vocab_id: Vocabulary.latest), notice: "New term pending version release was removed!"
  end
  # Replace one term with another and create redirect
  def replace
    @term = Term.get(params[:vocab_id], params[:id])
    @term_being_replaced = Term.find_by(id: params[:replacement_id].to_i)
    @vr = VersionRelease.find_by(id: params["vid"].to_i)

    if @term.blank? || @term_being_replaced.blank? || params[:vocab_id] == params[:replacement_id]
      redirect_to vocabulary_index_path(id: Vocabulary.latest), notice: "Replacement of term failed"
    else

      @term_being_replaced.redirect_term(@term, @vr.id, current_user.id)

      redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "The old term of #{@term_being_replaced.uri} should redirect here now."
    end
  end

  def restore
    @term = Term.get(params[:vocab_id], params[:id])

    set_restore_relations(@term)

    @term.visibility = "visible"
    @term.save!

    redirect_to vocabulary_show_path(vocab_id: Vocabulary.latest,  id: @term.identifier), notice: "Term was restored!"
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

  def verify_super_permissions
    if !current_user.present? || (!current_user.superuser?)
      redirect_to root_path
    end
  end
  def verify_admin_permissions
    if !current_user.present? || (!current_user.admin? && !current_user.superuser?)
      redirect_to root_path
    end
  end
  def verify_contrib_permissions
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.contributor?)
      redirect_to root_path
    end
  end
  def verify_suggester_permissions
    if !current_user.present? || (!current_user.admin? && !current_user.superuser? && !current_user.contributor? && !current_user.suggester?)
      redirect_to root_path
    end
  end

end

