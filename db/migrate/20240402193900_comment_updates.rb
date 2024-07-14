class CommentUpdates < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.column_exists?(:comments, :replaces_comment_id)
      add_reference :comments, :replaces_comment, foreign_key: { to_table: :comments }
    end
    unless ActiveRecord::Base.connection.column_exists?(:comments, :language_id)
      add_reference :comments, :language, foreign_key: true, type: :string, collation: "utf8mb3_unicode_ci"
      Comment.update_all(language_id: 'en')
    end
  end
  def down
    ActiveRecord::Base.connection.column_exists?(:comments, :replaces_comment_id) and remove_column :comments, :replaces_comment_id
    ActiveRecord::Base.connection.column_exists?(:comments, :language_id) and remove_column :comments, :language_id
  end
end
