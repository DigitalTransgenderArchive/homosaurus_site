class TermRelationship < ActiveRecord::Base
  self.table_name = "term_relationships"
  belongs_to :term
  belongs_to :relation
end
