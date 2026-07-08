class FixDatesOnRelease < ActiveRecord::Migration[5.2]
  def up
    VersionRelease.update(release_date: nil)
    change_column(:version_releases, :release_date, :datetime)
    VersionRelease.all.each do |vr|
      if vr.edit_requests.count > 0
        vr.update(release_date: vr.edit_requests.pluck(:created_at).max.to_datetime)
      end
    end

  end
  def down
    VersionRelease.update(release_date: nil)
    change_column(:version_releases, :release_date, :string)
  end
end
