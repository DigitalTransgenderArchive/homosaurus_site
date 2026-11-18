class FixErHistoryDuplicates < ActiveRecord::Migration[5.2]
  def up
    # Get all the terms that have been modified in both previous releases
    tids = VersionRelease.last.edit_requests.pluck(:term_id).to_set & VersionRelease.all[-2].edit_requests.pluck(:term_id).to_set
    # Loop through the terms / relations
    tids.each do |tid|
      term = Term.find_by(id: tid)
      pp "================== Analyzing Term #{tid} ====================="
      er361 = term.edit_requests()[-2]
      ermc361 = er361.my_changes
      er370 = term.edit_requests()[-1]
      ermc370 = er370.my_changes
      
      problem = false
      Relation.pluck(:id, :name).each do |rid, rname|
        erc361 = ermc361[rid]
        erc370 = ermc370[rid]
        shared = erc361.to_set & erc370.to_set
        diff = (erc370.to_set - erc361.to_set).to_a
        # If an edit is duplicated in both versions, flag it and cache the change
        if shared.count > 0
          pp "Relation #{rid} - #{rname}"
          pp erc361
          pp erc370
          pp shared
          problem = true
          ermc370[rid] = diff.to_a
        end
      end
      # If duplicates were detected, remove them
      if problem
        er370.update(my_changes: ermc370)
      end
    end
  end
end
