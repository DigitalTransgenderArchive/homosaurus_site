class VoteStatus < ActiveRecord::Base
  belongs_to :votable, polymorphic: true
  belongs_to :language
end
