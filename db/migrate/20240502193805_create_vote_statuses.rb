class CreateVoteStatuses < ActiveRecord::Migration[5.2]
  def up
    # Create a table for tracking statuses of terms across languages
    unless ActiveRecord::Base.connection.table_exists?(:vote_statuses)
      create_table :vote_statuses do |t|
        t.references :votable, polymorphic: true, null: false
        t.references :reviewer,  foreign_key: { to_table: :users }, type: :integer, null: true
        #t.references :language, null: true, foreign_key: true, type: :string, collation: "utf8mb3_unicode_ci"
        t.string :status
        t.timestamps
      end
      add_reference :vote_statuses, :language, foreign_key: true, type: :string, collation: "utf8mb3_unicode_ci"
      #VoteStatus.update_all(language_id: 'en')
    end
    # Clean up language codes
    if Language.where(id: "spa").count > 0
      Language.create([{:id => "es", :name => "Spanish", :approval_cutoff => 5}])
      TermRelationship.where(language_id: "spa").update_all(language_id: "es")
      Language.find_by(id: "spa").delete
    end
    if Language.where(id: "ben").count > 0
      Language.create([{:id => "bn", :name => "Bengali", :approval_cutoff => 5}])
      TermRelationship.where(language_id: "ben").update_all(language_id: "bn")
      Language.find_by(id: "ben").delete
    end
    if Language.where(id: "fr").count == 0
      Language.create([{:id => "fr", :name => "French", :approval_cutoff => 5},
                       {:id => "nl", :name => "Dutch",  :approval_cutoff => 5},
                       {:id => "sv", :name => "Swedish", :approval_cutoff => 5},
                       {:id => "hi", :name => "Hindi", :approval_cutoff => 5},
                      ])
    end
    # Add a supported field for interfaced languages
    unless ActiveRecord::Base.connection.column_exists?(:languages, :supported)
      add_column :languages, :supported, :boolean
      Language.update_all(supported: false)
      Language.where(id: ["en", "es", "fr", "nl", "sv", "hi", "bn"]).update_all(supported: true)
    end

      # Populate the table
      statuses = EditRequest.where(parent_id: nil).where(status: "approved").map{|er| {:votable => er, :reviewer_id => nil,
                                                                 :language_id => "en", :status => "approved"} }
      VoteStatus.create!(statuses)    

    #Make langs optional for roles
    #change_column_null :roles_users, :language_id, true
  end
  def down
    if ActiveRecord::Base.connection.table_exists?(:vote_statuses)
      drop_table :vote_statuses
    end
    if ActiveRecord::Base.connection.column_exists?(:languages, :supported)
      remove_column :languages, :supported
    end
    #change_column_null :roles_users, :language_id, false
  end
end
