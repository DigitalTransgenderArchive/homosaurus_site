class AddSourceAndContributor < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:terms, :sources)
      change_table :terms do |t|
        # Serialized data
        t.text :sources
        t.text :contributors
      end
    end
  end
end
