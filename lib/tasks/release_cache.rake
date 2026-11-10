namespace :releases do
  desc "Fill the release statistics and card caches"
  task warm_cache: :environment do
    VersionRelease.list_statistics
    VersionRelease.manage_statistics
    VersionRelease.find_each do |release|
      release.card_index(false)
      release.card_index(true)
    end
  end
end
