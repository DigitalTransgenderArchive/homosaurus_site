class TermRelationship < ActiveRecord::Base
  self.table_name = "term_relationships"
  belongs_to :term
  belongs_to :relation

  def linked_term
    return Term.find_by(id: self.data.to_i)
  end
  
end
