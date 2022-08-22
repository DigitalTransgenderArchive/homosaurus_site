class HomosaurusExactmatchLcsh < SecondBase::Base
  belongs_to :homosaurus_subject
  belongs_to :lcsh_subject

  self.table_name = "dta.homosaurus_exactmatch_lcsh"
end