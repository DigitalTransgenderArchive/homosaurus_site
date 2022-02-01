class LcshSubject < SecondBase::Base
  self.table_name = "dta.lcsh_subjects"

  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array

end
