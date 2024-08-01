class AddPendings < ActiveRecord::Migration[5.2]
  def up
    change_column_null :edit_requests, :term_id, true
    change_column_null :edit_requests, :version_release_id, true
    add_column :version_releases, :status, :text #Published, Pending, Unversioned
    VersionRelease.update_all(status: "Published")
    EditRequest.where(parent_id: nil).each do |er|
      status = (er.version_release.status == "Published") ? "approved"  : "pending"
      EditRequest.create!(:term_id => nil,
                          :created_at => er.created_at,
                          :version_release_id => nil,
                          :status => "approved",
                          :my_changes => er.my_changes,
                          :parent_id => er.id)
      #pp "created?"
    end
  end
  def down
    EditRequest.where.not(parent_id: nil).destroy_all()
    change_column_null :edit_requests, :term_id, false
    change_column_null :edit_requests, :version_release_id, false
    # VersionRelease.where("release_identifier LIKE '%.%.%'").each do |vr|
    #   vr.update(release_identifier: vr.release_identifier.slice(0, 3))
    # end
    remove_column :version_releases, :status
    VersionRelease.where("id > 12").destroy_all()
    #VersionRelease.where(id: 12).destroy_all()
    Vocabulary.where(id: 4).destroy_all()
  end
end
