class EditRequest < ActiveRecord::Base
  has_many :comments, as: :commentable
  belongs_to :term
  belongs_to :version_release
  serialize  :my_changes
  belongs_to :parent, :class_name => 'EditRequest', optional: true
  has_many :children, :class_name => 'EditRequest', :foreign_key => 'parent_id'
  #accepts_nested_attributes_for :my_changes
  
  def self.makeFromTerm(term_id, version_release_id)
    my_changes = Hash.new
    t = Term.find_by(id: term_id)
    er_history = t.get_edit_requests()
    if er_history.count > 0
      prev_er = er_history[0]
    elsif not t.replaces.nil?
      prev_er = Term.find_by(uri: t.replaces).get_edit_requests()[0]
    end
    Relation.pluck(:id).each do |r|
      my_changes[r] = Array.new
      t.term_relationships.where(relation_id: r).each do |tr|
        d = ["+", tr.language_id, tr.data]
        unless prev_er and prev_er.my_changes[r].include?(d)
          my_changes[r] << d
        end
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
  def self.makeEmptyER(term_id, created_at, vid, vis = "Published", uri = "", identifier = "", parent = nil)
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
                              :my_changes => my_changes,
                              :parent_id => parent)
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
