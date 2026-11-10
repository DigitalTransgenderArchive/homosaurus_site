class AddProfileToUsers < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.column_exists?(:users, :username)
      add_column :users, :username, :string, unique: true
      add_column :users, :fname, :string
      add_column :users, :lname, :string
      add_column :users, :bio, :text


      User.all.each do |u|
        u.update(username: u.email)
        u.save!
      end
    end
    unless Role.count > 4
      Role.create(id: 5, name: "suggester")
    end
  end
  def down
    remove_column :users, :username, :string, unique: true
    remove_column :users, :fname, :string
    remove_column :users, :lname, :string
    remove_column :users, :bio, :text
    unless Role.count == 4
      Role.delete(5)
    end
  end
end
