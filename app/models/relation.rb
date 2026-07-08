class Relation < ActiveRecord::Base
  Description = 1
  Pref_label = 2
  Label = 3
  Alt_label = 4
  Replaced_by = 5
  Narrower = 6
  Broader = 7
  Related = 8
  Lcsh_exact = 9
  Lcsh_close = 10
  Close_match = 11
  Exact_match = 12
  Redirects_to = 13
  History_note = 14
  Contributors = 15
  Sources = 16
  ValueStruct = Struct.new(:data, :language_id)
  self.table_name = "relations"
  has_many :term_relationships

  def self.inverse(rid)
    if rid == Relation::Narrower
      return Relation::Broader
    elsif rid == Relation::Broader
      return Relation::Narrower
    elsif rid == Relation::Related
      return Relation::Related
    end
  end
end
