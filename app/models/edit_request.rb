class EditRequest < ActiveRecord::Base
  belongs_to :term
  belongs_to :version_release
  serialize  :my_changes
  #accepts_nested_attributes_for :my_changes
  
  def self.makeFromTerm(term_id, version_release_id)    
    my_changes = Hash.new
    t = Term.find_by(id: term_id)
    Relation.pluck(:id).each do |r|
      my_changes[r] = Array.new
      t.term_relationships.where(relation_id: r).each do |tr|
        my_changes[r] << ["+", tr.language_id, tr.data]
      end
    end
    my_changes["visibility"] = t.visibility
    my_changes["uri"] = t.uri
    my_changes["identifier"] = t.identifier
    # pp my_changes
    replaces = t.replaces
    if t.replaces
      replaces = Term.find_by(uri: replaces).id
    end
    er = EditRequest.new(:term_id => term_id,
                         :prev_term_id => replaces,
                         :created_at => t.created_at,
                         :version_release_id => version_release_id,
                         :status => "published",
                         :my_changes => my_changes)

    er.save!
    
  end
  def self.makeEmptyER(term_id, created_at, vid, vis = "Published", uri = "", identifier = "")
    my_changes = Hash.new
    Relation.pluck(:id).each do |r|
      my_changes[r] = Array.new
    end
    my_changes["visibility"] = vis
    my_changes["uri"] = uri
    my_changes["identifier"] = identifier
    return EditRequest.create(:term_id => term_id,
                              :created_at => created_at,
                              :version_release_id => vid,
                              :status => "published",
                              :my_changes => my_changes)
  end

  def previous()
    er_index = self.term.edit_requests.find_index(self)
    if er_index == 0
      if self.prev_term_id.nil?
        return nil
      end
      return Term.find_by(id: self.prev_term_id).edit_requests[-1]
    else
      return self.term.edit_requests[er_index - 1]
    end
  end

end
