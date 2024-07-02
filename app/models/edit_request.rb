class EditRequest < ActiveRecord::Base
  has_many :comments, as: :commentable
  has_many :vote_statuses, as: :votable
  belongs_to :term, optional: true
  belongs_to :version_release, optional: true
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id', optional: true
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
                         :status => "approved",
                         :my_changes => my_changes)

    er.save!
  end
  def self.makeEmptyER(term_id, created_at, vid, vis = "Published", uri = "", identifier = "", parent = nil)
    my_changes = EditRequest::makeChangeHash(vis, uri, identifier)
    return EditRequest.create(:term_id => term_id,
                              :created_at => created_at,
                              :version_release_id => vid,
                              :status => "approved",
                              :my_changes => my_changes,
                              :parent_id => parent)
  end
  def self.makeChangeHash(visibility, uri, identifier)
    my_changes = Hash.new
    Relation.pluck(:id).each do |r|
      my_changes[r] = Array.new
    end
    my_changes["uri"] = uri
    my_changes["identifier"] = identifier
    return my_changes
  end
  def addChange(rel_id, change)
    inverse_change = [change[0] == "+" ? "-" : "+", change[1], change[2]]
    if self.my_changes[rel_id].include? inverse_change
      self.my_changes.remove!(inverse_change)
    else
      self.my_changes[rel_id] << change
    end
  end
  def voteSummary()
    pp "LOCALE IS #{I18n.locale}"
    votes = self.comments.where(language_id: I18n.locale).where(replaces_comment_id: nil).where(is_vote: true).map{ |c| c.subject }
    return votes.uniq.map{ |v| [v, votes.count(v)] }.to_h
  end

  def hasUserVoted(user)
    return self.comments.where(replaces_comment_id: nil).where(is_vote: true).where(user_id: user.id).count > 0
  end

  def getVoteStatus(lang_id)
  end

  def term
    super || self.parent.term
  end
  def version_release
    super || self.parent.version_release
  end
  
  def previous()
    unless self.parent_id.nil?
      er_index = self.parent.children.find_index(self)
      if er_index == 0
        return self.parent.previous()
      else
        return self.parent.children[er_index - 1]
      end
    end
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

  def vote_status
    vs = self.vote_statuses[0]#.find_by(language_id: I18n.locale)
    if vs.nil?
      return "pending"
    end
    return vs.status
  end
end
