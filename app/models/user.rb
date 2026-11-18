class User < ActiveRecord::Base
  include Hydra::RoleManagement::UserRoles
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  after_create :setup_permissions

  has_many :comments
  has_many :user_language_roles

  has_many :profile_comments, :class_name => 'Comment', as: :commentable

  has_many :edit_requests, :class_name => 'EditRequest', :foreign_key => 'creator_id'

  alias_attribute :user_key, :email


  def setup_permissions
    self.update(username: self.email)
    # Make suggester for all languages
    Language.where(supported: true).each do |l|
      UserLanguageRole.create(user_id: self.id, language_id: l.id, role_id: 5)
    end
  end
  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def name
    email
  end

  def superuser?
    #return false
    roles.where(name: 'superuser').exists?
  end
  
  def admin?
    #return false
    roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def contributor?
    #return false
    roles.where(name: 'contributor').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def suggester?
    roles.where(name: 'suggester').exists?
  end

  def homosaurus?
    #return false
    roles.where(name: 'homosaurus').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

end
