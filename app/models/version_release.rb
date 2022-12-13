class VersionRelease < ActiveRecord::Base
  belongs_to :vocabulary
  has_many :version_release_term
end