class CreateLanguages < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?(:languages)
      create_table :languages, id: false do |t|
        t.string     :id,              null: true, index: true, unique: true
        t.integer    :approval_cutoff, null: false
        t.string     :name,            null: false # csv: lang1name@lang1, lang2name@lang2, ...
        t.references :localizes_language, foreign_key: { to_table: :languages }, index: false, type: :string
      end
      Language.create(
        [
          {:id => "en",    :name => "English",       :approval_cutoff => 5},
          {:id => "en-US", :name => "English (USA)", :approval_cutoff => 5, :localizes_language_id => "en"},
          {:id => "en-GB", :name => "English (UK)",  :approval_cutoff => 5, :localizes_language_id => "en"},
          {:id => "spa",   :name => "Spanish",       :approval_cutoff => 5},
          {:id => "zh",    :name => "Chinese",       :approval_cutoff => 5},
          {:id => "ar",    :name => "Arabic",        :approval_cutoff => 5},
          {:id => "ja",    :name => "Japanese",      :approval_cutoff => 5},
          {:id => "ta",    :name => "Tamil"   ,      :approval_cutoff => 5},
          {:id => "hil",   :name => "Hiligaynon",    :approval_cutoff => 5},
          {:id => "fij",   :name => "Fijian",        :approval_cutoff => 5},
          {:id => "haw",   :name => "Hawaiian",      :approval_cutoff => 5},
          {:id => "niu",   :name => "Niuean",        :approval_cutoff => 5},
          {:id => "pmy",   :name => "Papuan Malay",  :approval_cutoff => 5},
          {:id => "rar",   :name => "Rarotongan",    :approval_cutoff => 5},
          {:id => "smo",   :name => "Samoan",        :approval_cutoff => 5},
          {:id => "tah",   :name => "Tahitian",      :approval_cutoff => 5},
          {:id => "ton",   :name => "Tonga",         :approval_cutoff => 5},
          {:id => "tha",   :name => "Thai",          :approval_cutoff => 5},
          {:id => "km",    :name => "Khmer",         :approval_cutoff => 5},
          {:id => "mi",    :name => "Maori",         :approval_cutoff => 5},
          {:id => "egy",   :name => "Egyptian (Ancient)", :approval_cutoff => 5},
        ]
      )
    end
    
  end
  def down
    drop_table :languages
  end
end
