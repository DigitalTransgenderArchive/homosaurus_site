class AddLanguageToRoles < ActiveRecord::Migration[5.2]
  def up
    unless Role.count() > 2
      Role.update(2, :name => 'admin')
      ActiveRecord::Base.connection.execute("INSERT into roles (name) VALUES ('working group member')")
      ActiveRecord::Base.connection.execute("INSERT into roles (name) VALUES ('contributor')")
      ActiveRecord::Base.connection.execute("UPDATE roles_users SET role_id = 4 WHERE role_id = 2")
    end
    # Add languages to user roles
    unless ActiveRecord::Base.connection.column_exists?(:roles_users, :language_id)
      add_reference :roles_users, :language, foreign_key: true
    end
    if ActiveRecord::Base.connection.column_exists?(:roles_users, :language_id)
      ActiveRecord::Base.connection.execute("UPDATE roles_users SET language_id = 'en' WHERE language_id is NULL")
    end
  end
end
