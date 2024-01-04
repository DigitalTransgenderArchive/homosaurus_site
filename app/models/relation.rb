class Relation < ActiveRecord::Base
  self.table_name = "relations"
  has_many :term_relationships
end
