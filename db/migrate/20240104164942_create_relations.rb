class CreateRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :relations do |t|
      t.string  :name,     null: false, unique: true
      t.integer :links_to, :default => 0 # 1 for terms, 2 for lcsh_subject_cache
    end
    unless Relation.count() > 1
      Relation.create(
        [
          {:name => "Description"},
          {:name => "Preferred Label"},
          {:name => "Label"},
          {:name => "Alternative Label"},
          {:name => "Replaced By", :links_to => 1},
          {:name => "Narrower", :links_to => 1},
          {:name => "Related", :links_to => 1},
          {:name => "LCSH Exact Match", :links_to => 2},
          {:name => "LCSH Close Match", :links_to => 2},
          {:name => "Close Match", :links_to => 1},
          {:name => "Exact Match", :links_to => 1},
        ] 
      )
    end
  end
end
