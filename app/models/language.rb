class Language < ActiveRecord::Base
  self.table_name = "languages"
  self.primary_key = "id"
  has_many :term_relationships
  belongs_to :parent, :class_name => 'Language', optional: true
  has_many :localizations, :class_name => 'Language', :foreign_key => 'localizes_language_id'

  has_many :user_language_roles 

  def self.supported
    Language.all.where(supported: true)
  end
end
