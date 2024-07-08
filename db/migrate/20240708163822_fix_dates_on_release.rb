class FixDatesOnRelease < ActiveRecord::Migration[5.2]
  def up
    VersionRelease.update(release_date: nil)
    change_column(:version_releases, :release_date, :timestamp)
    VersionRelease.all.each do |vr|
      if vr.edit_requests
        vr.update(release_date: vr.edit_requests.pluck(:created_at).max)
      end
    end

  end
  def down
    VersionRelease.update(release_date: nil)
    change_column(:version_releases, :release_date, :string)
  end
end
