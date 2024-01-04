class CreateLanguages < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.table_exists?(:languages)
      create_table :languages, id: false do |t|
        t.string  :id,              null: false, index: true, unique: true
        t.integer :approval_cutoff, null: false
        t.string  :name,           null: false # csv: lang1name@lang1, lang2name@lang2, ...
      end
      Language.create([{:id => "en", :name => "English", :approval_cutoff => 5}])
    end
  end
end
