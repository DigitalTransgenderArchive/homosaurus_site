class FixEditRequestHistory < ActiveRecord::Migration[5.2]
  def pluck_from_hist(from_er, to_version, rel_id, rel_term)
    
    to_er = to_version.edit_requests.where(term_id: from_er.term.id).first() or nil
    term = from_er.term
    unless to_er
      my_changes = EditRequest::makeChangeHash(term.visibility, from_er.my_changes["uri"], term.identifier)
      to_er = EditRequest.new(:term_id => term.id,
                              :created_at => from_er.created_at,
                              :version_release_id => to_version.id,
                              :my_changes => my_changes,
                              :parent_id => nil,
                              :status => "approved")
    end
    er_change = EditRequest.new(:term_id => nil,
                                :creator_id => from_er.creator_id,
                                :created_at => from_er.created_at,
                                :version_release_id => nil,
                                :status => "approved",
                                :my_changes => EditRequest::makeChangeHash(term.visibility, from_er.my_changes["uri"], term.identifier),
                                :parent_id => to_er.id)

    orig_changes = from_er.my_changes
    orig_changes[rel_id].delete(["+", nil, "#{rel_term.id}"])
    from_er.update!(my_changes: orig_changes)
    from_er.children.each do |erc|
      erc_c = erc.my_changes
      erc_c.delete(["+", nil, "#{rel_term.id}"])
      erc.update!(my_changes: erc_c)
    end
    er_change.my_changes[rel_id] << ["+", nil, "#{rel_term.id}"]
    er_change.save!
    to_er.my_changes[rel_id] << ["+", nil, "#{rel_term.id}"]
    to_er.save!
    
  end
  def up
    EditRequest.where(parent_id: nil).each do |er|
      er.my_changes.slice(Relation::Broader, Relation::Narrower, Relation::Related).each do |k, v|
        terms = v.map{|r| Term.find_by(id: r[2].to_i)}
        terms.each do |t|
          if er.version_release.id < t.first_introduced().id
            pp [er.my_changes["uri"], er.version_release.release_identifier, t.uri, t.first_introduced().release_identifier]
            pluck_from_hist(er, t.first_introduced(), k, t)
          end
        end
      end
    end
  end
  def down
  end
end
