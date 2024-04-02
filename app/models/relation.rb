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
  ValueStruct = Struct.new(:data, :language_id)
  self.table_name = "relations"
  has_many :term_relationships
end
