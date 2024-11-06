class RemoveErDuplicates < ActiveRecord::Migration[5.2]
  def up
    EditRequest.all.each do |er|
      loc_changes = er.my_changes
      Relation.pluck(:id).each do |rid|
        if loc_changes[rid].to_set.to_a != loc_changes[rid].to_a
          pp "Duplicates detected! Removing..."
          pp "Edit Request ID #{er.id}"
          pp "Relation ID #{rid}"
          pp "Detected values:"
          pp loc_changes[rid]
          pp "Updated values:"
          pp loc_changes[rid].to_set.to_a
          loc_changes[rid] = loc_changes[rid].to_set.to_a
          er.update(my_changes: loc_changes)
          er.save!
          pp "==========================="
        end
      end
    end
  end
end
