class CreateVersionRelease < ActiveRecord::Migration[5.2]

  def change
    unless ActiveRecord::Base.connection.table_exists?(:version_releases)
      create_table :version_releases do |t|
        t.string   :release_identifier, null: false, index: { unique: true }
        t.string   :release_type, null: false  # Major, Minor, Etc
        t.string   :release_date # String representation of the release
        t.timestamps null: false
        t.string :vocabulary_identifier, index: true
        t.belongs_to :vocabulary
      end

      create_table :version_release_terms do |t|
        t.string   :change_type, null: false, index: true
        t.string   :term_uri, null: false, index: true
        t.string   :term_identifier, null: false, index: true
        t.string   :previous_label
        t.string   :previous_label_language
        t.timestamps null: false
        t.belongs_to :version_release
        t.belongs_to :term
      end
    end
  end
end
