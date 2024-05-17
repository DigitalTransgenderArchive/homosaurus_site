class User < ActiveRecord::Base
  include Hydra::RoleManagement::UserRoles
  has_many :comments
  has_many :user_language_roles 

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  alias_attribute :username, :email
  alias_attribute :user_key, :email

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def name
    email
  end

  def admin?
    #return false
    roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def superuser?
    #return false
    roles.where(name: 'superuser').exists?
  end

  def contributor?
    #return false
    roles.where(name: 'contributor').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def homosaurus?
    #return false
    roles.where(name: 'homosaurus').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

end
