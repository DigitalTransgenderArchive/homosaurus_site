class AddLcshSubjectCache < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:lcsh_subject_cache)

      create_table :lcsh_subject_cache do |t|
        t.string :uri, index: { unique: true }
        t.string :label

        # Serialized data
        t.text :alt_labels
        t.text :broader
        t.text :narrower
        t.text :related
      end

    end
  end
end
