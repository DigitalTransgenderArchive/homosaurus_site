class HomosaurusClosematchLcsh < SecondBase::Base
  belongs_to :homosaurus_subject
  belongs_to :lcsh_subject

  self.table_name = "dta.homosaurus_closematch_lcsh"

end