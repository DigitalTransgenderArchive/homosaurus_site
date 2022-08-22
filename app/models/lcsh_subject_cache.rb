class LcshSubjectCache < ActiveRecord::Base
  self.table_name = "lcsh_subject_cache"

  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array

end
