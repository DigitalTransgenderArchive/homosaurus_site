class Language < ActiveRecord::Base
  self.table_name = "languages"
  has_many :term_relationships
end
