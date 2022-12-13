class VersionReleaseTerm < ActiveRecord::Base
  belongs_to :version_release
  belongs_to :term
end