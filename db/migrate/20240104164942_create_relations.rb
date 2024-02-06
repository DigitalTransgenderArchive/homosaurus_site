class CreateRelations < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?(:relations)
      create_table :relations do |t|
        t.string  :name,     null: false, unique: true
        t.integer :links_to, :default => 0 # 1 for terms, 2 for lcsh_subject_cache
        t.string  :description
        t.string  :description_url
        t.boolean :serializable, :default => false
      end
      Relation.create(
        [
          {:name => "Description",
           :description => "Definition of Comment in the RDF Schema Vocabulary",
           :description_url => "http://www.w3.org/2000/01/rdf-schema#comment"},
          {:name => "Preferred Label",
           :description => "Definition of Preferred Label in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#prefLabel"},
          {:name => "Label",
           :description => "Definition of Label in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#prefLabel"},
          {:name => "Alternative Label",
           :description => "Definition of Alternative Label in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#altLabel"},
          {:name => "Replaced By", :links_to => 1,
           :description => "Definition of isReplacedBy in the Dublin Core Terms Vocabulary",
           :description_url => "http://purl.org/dc/terms/isReplacedBy"},
          {:name => "Narrower", :links_to => 1,
           :description => "Definition of Narrower in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#narrower"},
          {:name => "Broader", :links_to => 1,
           :description => "Definition of Broader in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#broader"},
          {:name => "Related", :links_to => 1,
           :description => "Definition of Related in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#related"},
          {:name => "LCSH Exact Match", :links_to => 2},
          {:name => "LCSH Close Match", :links_to => 2},
          {:name => "Close Match", :links_to => 1,
           :description => "Definition of Modified in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#closeMatch"},
          {:name => "Exact Match", :links_to => 1,
           :description => "Definition of exactMatch in the SKOS Vocabulary",
           :description_url => "http://www.w3.org/2004/02/skos/core#exactMatch"},
          {:name => "Redirects to", :links_to => 1}
        ] 
      )
    end
  end
  def down
    if ActiveRecord::Base.connection.table_exists?(:relations)
      drop_table :relations
    end
  end
end
