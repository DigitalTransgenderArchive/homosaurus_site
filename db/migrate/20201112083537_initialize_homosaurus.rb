class InitializeHomosaurus < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:vocabularies)

      create_table :vocabularies do |t|
        t.string :identifier, index: { unique: true }
        t.string :name
        t.string :base_uri
        t.string :solr_model
        t.string :visibility, index: true, limit: 50
        t.string :version, limit: 50
        t.timestamps null: false
      end

     # Missing Hierarchy
      create_table :terms do |t|
        t.string :pid, index: { unique: true }, limit: 128
        t.integer :numeric_pid, index: true
        t.string :uri, index: { unique: true }
        t.string :identifier, index:true, limit: 128
        t.string :pref_label
        t.string :pref_label_language
        t.text :description
        t.string :visibility, index: true, limit: 50
        t.string :is_replaced_by, index: true
        t.string :replaces, index: true
        t.timestamps null: false
        t.datetime :manual_update_date, null: false

        # Serialized data
        t.string :labels
        t.string :labels_language
        t.text :alt_labels
        t.text :alt_labels_language
        t.text :broader
        t.text :narrower
        t.text :related
        t.text :close_match
        t.text :exact_match
        t.text :close_match_homosaurus
        t.text :exact_match_homosaurus
        t.text :close_match_lcsh
        t.text :exact_match_lcsh

        t.string :vocabulary_identifier, index: true
        t.belongs_to :vocabulary
      end

    end
  end
end
