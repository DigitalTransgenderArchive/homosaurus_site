class UserLanguageRole < ActiveRecord::Base
  self.table_name = "roles_users"
  belongs_to :user
  belongs_to :language,  optional: true
  belongs_to :role
end
