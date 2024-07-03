class AdminController < ApplicationController
  before_action :verify_permission

  def version_new
    @version_release = VersionRelease.create(
      #:id => pendings.id - 1,
      :release_identifier => VersionRelease::get_next_identifier(params[:release_type]),
      :release_type => params[:release_type],
      :created_at => DateTime.now,
      :updated_at => DateTime.now,
      :vocabulary_identifier => "v3",
      :vocabulary_id => 3,
      :status => "Pending")
    redirect_to version_manage_path
  end
  def version_publish
    @vr = VersionRelease.find_by(release_identifier: params[:release_identifier])
    @vr.update(status: "Published")
    @vr.approved_edit_requests.each do |er|
      if er.term.visibility == "pending"
        er.term.update(visibility: "visible")
        er.save
      end
    end
    # @vr.approved_edit_requests.each do |er|
    #   er.term.add_relations(@vr.id, current_user.id)
    # end
    @vr.approved_edit_requests.each do |er|
      t = er.term
      tr = t.get_relationships_at_version_release(@vr.id)
      
      TermRelationship.where(term_id: t.id).delete_all
      Relation.all.each do |r|
        tr[r.id].each do |rel|
          TermRelationship.create(term_id: t.id,
                                  relation_id: r.id,
                                  language_id: rel[0],
                                  data: rel[1])
        end
      end

      if tr[Relation::Redirects_to].count > 0
        pp tr
        if tr[Relation::Redirects_to][0][1] == "0"
          t.update(visibility: "deleted")
        else
          t.is_replaced_by = Term.find_by(id: tr[Relation::Redirects_to][0][1].to_i).uri
          t.update(visibility: "redirect")
        end
        t.save!
      end
    end
    Spawnling.new do
      DSolr.reindex_all
    end
    redirect_to version_manage_path
  end
  def version_manage
    @version_release = VersionRelease.new
  end
  def version_create
    updated_term_identifiers = []
    ActiveRecord::Base.transaction do
      @version_release = VersionRelease.new
      @version_release.release_type = "Major"
      @version_release.vocabulary_identifier = "v3"
      @version_release.vocabulary = Vocabulary.find_by(identifier: "v3")
      @version_release.update(version_release_params)
      @version_release.save!

      @new_terms = Term.where(vocabulary_identifier: "v3", visibility: "pending")
      @new_terms.each do |term|
        version_release_term = VersionReleaseTerm.new
        version_release_term.change_type = "new"
        version_release_term.term_uri = term.uri
        version_release_term.term_identifier = term.identifier
        version_release_term.version_release = @version_release
        version_release_term.term = term
        version_release_term.save!

        term.visibility = "visible"
        term.save!
        updated_term_identifiers << term.identifier
      end

      @edited_terms = Hist::Pending.all
      @edited_terms.each do |term_needs_reify|
        term = term_needs_reify.reify
        previous_term_state = Term.find_by(identifier: term.identifier)

        if term.pref_label != previous_term_state.pref_label
          version_release_term = VersionReleaseTerm.new
          version_release_term.change_type = "update"
          version_release_term.term_uri = term.uri
          version_release_term.term_identifier = term.identifier
          version_release_term.previous_label = previous_term_state.pref_label
          version_release_term.previous_label_language = previous_term_state.pref_label_language
          version_release_term.version_release = @version_release
          version_release_term.term = term
          version_release_term.save!
        end

        term.visibility = "visible"
        term.save!
        term_needs_reify.destroy!
        updated_term_identifiers << term.identifier
      end
    end

    # FIXME: What about relationships that are removed?...
    updated_term_identifiers.each do |identifier|
      term = Term.find_by(identifier: identifier)

      if term.broader.present?
        term.broader.each do |broader|
          if broader.present?
            broader_object = Term.find_by(uri: broader)
            broader_object.narrower = broader_object.narrower + [term.uri]
            broader_object.narrower.uniq
            broader_object.save
          end
        end
      end

      if term.narrower.present?
        term.narrower.each do |narrower|
          if narrower.present?
            narrower_object = Term.find_by(uri: narrower)
            narrower_object.broader = narrower_object.broader + [term.uri]
            narrower_object.broader.uniq
            narrower_object.save
          end

        end
      end

      if term.related.present?
        term.related.each do |related|
          if related.present?
            #related = related.split("(").last[0..-1]
            related_object = Term.find_by(uri: related)
            related_object.related = related_object.related + [term.uri]
            related_object.related.uniq
            related_object.save
          end
        end
      end
    end

    redirect_to vocabulary_term_new_path(vocab_id: "v3")
  end

  def user_manage
    @users = User.all
  end

  def user_update
    ulr = params["user_language_role"].to_unsafe_h
    ulr["language_id"] = ulr["language_id"] == '' ? nil : ulr["language_id"]
    ulr["role_id"] = params["role_id"]
    ulr_obj = UserLanguageRole.where(user_id: ulr["user_id"]).where(language_id: ulr["language_id"])
    if ulr["role_id"] == ""
      ulr_obj.delete_all()
    else
      if ulr_obj.count > 0
        ulr_obj.update_all(role_id: ulr["role_id"])
      else
        ulr_obj = UserLanguageRole.create(ulr)
      end
    end
    redirect_to user_manage_path
  end
  # From: https://github.com/CollegeOfTheHolyCross/dta_sufia/blob/bd445b07af17175d886cf8ee4eb9a1609daec231/app/controllers/commands_controller.rb
  def restart_application
    `git pull origin master`
    `bundle exec rake assets:precompile --trace RAILS_ENV=production`
    `service apache2 reload`
    #`touch tmp/restart.txt`

    respond_to do |format|
      format.html { render :text => "Updated." }
    end
  end

  def verify_permission
    if !current_user.superuser?
      redirect_to root_path
    end
  end

  def version_release_params
    params.require(:version_release).permit(:release_identifier, :release_date)
  end
end
