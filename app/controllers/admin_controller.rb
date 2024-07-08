class AdminController < ApplicationController
  before_action :verify_permission
  # Create a new release
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
    shuffle_pending_terms()
    redirect_to version_manage_path
  end
  # Publish an existing release 
  def version_publish
    @vr = VersionRelease.find_by(release_identifier: params[:release_identifier])
    @vr.update(status: "Published")
    @vr.update(release_date: DateTime.now)
    @vr.approved_edit_requests.each do |er|
      if er.term.visibility == "pending"
        er.term.update(visibility: "visible")
        er.save
      end
    end
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
    shuffle_pending_terms()
    Spawnling.new do
      DSolr.reindex_all
    end
    redirect_to version_manage_path
  end
  # View for managing releases 
  def version_manage
    @version_release = VersionRelease.new
    pendings = VersionRelease.where(status: "Pending")
    @first_pending_id = pendings.count > 0 ? pendings[0].id : 0
  end

  # Internal function, moves pending terms in approved releases to new releases
  def shuffle_pending_terms
    if VersionRelease.where(status: "Pending").count == 0
      return
    end
    first_pending = VersionRelease.where(status: "Pending")[0]
    new_vid = first_pending.id

    # Move pending terms up a release
    VersionRelease.where(status: "Published").each do |vr|
      vr.edit_requests.where(status: "pending").each do |er|
        #if er.term.visibility == "pending"
        er.update(version_release_id: new_vid)
        #end
      end
    end
    
  end
  # View for managing users
  def user_manage
    @users = User.all
  end
  # Change the permission for a user in a given language or all
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
  # Allows admin to update the app from github and restart
  # From: https://github.com/CollegeOfTheHolyCross/dta_sufia/blob/bd445b07af17175d886cf8ee4eb9a1609daec231/app/controllers/commands_controller.rb
  def restart_application
    `git pull origin`
    `bundle exec rake assets:precompile --trace RAILS_ENV=production`
    `service apache2 reload`
    #`touch tmp/restart.txt`

    respond_to do |format|
      format.html { render :text => "Updated." }
    end
  end
  # Only superusers can access most functionality
  def verify_permission
    if !current_user.superuser?
      redirect_to root_path
    end
  end

  def version_release_params
    params.require(:version_release).permit(:release_identifier, :release_date)
  end
end
