class DelinkingFixes < ActiveRecord::Migration[5.2]
  def up
    # Manual fix - edit requests are linking to a defunct term
    if Term.find_by(id: 7527)
      er1 = EditRequest.find_by(id: 17940)
      myc = er1.my_changes
      myc[6] = [["+", nil, "5408"]]
      er1.update(my_changes: myc)
      er2 = EditRequest.find_by(id: 17956)
      myc2 = er2.my_changes
      myc2[6] = []
      er2.update(my_changes: myc2)
      Term.delete(7527)
    end
  end
end
