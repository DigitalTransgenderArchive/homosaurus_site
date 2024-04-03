class Comment < ActiveRecord::Base
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  has_many :comments, as: :commentable

  def get_root_type
    if self.commentable_type == "Comment"
      return self.commentable.get_root_type()
    else
      return self.commentable_type
    end
  end

  # Returns the term or edit request this comment is related to 
  def get_root
    if self.commentable_type == "Comment"
      return self.commentable.get_root()
    else
      return self.commentable
    end
  end

  def thread_last_active
    time = self.updated_at
    arr = [self]
    while arr.count > 0
      current = arr.shift
      if current.updated_at > time
        time = current.updated_at
      end
      current.comments.each do |c|
        arr << c
      end
    end
    return time
  end

  def self.vote_badge_class(subject)
    return "badge text-bg-" + (
             case subject
             when "Reject"
               "danger"
             when "Accept"
               "success"
             when "Table"
               "warning"
             else
               "secondary"
             end)
  end
  def vote_badge_class
    return '' if not self.is_vote
    return Comment::vote_badge_class(self.subject)
  end

  # Override the default getters to grab the subject/content of the latest revision
  def subject
    replacements = Comment.where(replaces_comment_id: self.id)
    if replacements.count > 0
      return replacements[-1].subject
    else
      return self[:subject]
    end
  end

  def content
    replacements = Comment.where(replaces_comment_id: self.id)
    if replacements.count > 0
      return replacements[-1].content
    else
      return self[:content]
    end
  end
end
