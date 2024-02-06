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
          {:id => "ta",    :name => "Tamil",         :approval_cutoff => 5},
          {:id => "ben",   :name => "Bengali",       :approval_cutoff => 5},
          {:id => "pa",    :name => "Panjabi",       :approval_cutoff => 5},
          {:id => "ur",    :name => "Urdu",          :approval_cutoff => 5},
          {:id => "mov",   :name => "Mohave",        :approval_cutoff => 5},
          {:id => "he",    :name => "Hebrew",        :approval_cutoff => 5},
          {:id => "mdy",   :name => "Maale (Ethiopian)", :approval_cutoff => 5},
          {:id => "fil",   :name => "Filipino",      :approval_cutoff => 5},
          {:id => "tsg",   :name => "Tausug",        :approval_cutoff => 5, :localizes_language_id => "fil"},
          {:id => "ceb",   :name => "Cebuano",       :approval_cutoff => 5, :localizes_language_id => "fil"},
          {:id => "tl",    :name => "Tagalog",       :approval_cutoff => 5, :localizes_language_id => "fil"},
          {:id => "bug",   :name => "Buginese",      :approval_cutoff => 5},
          {:id => "zap",   :name => "Zapotec",       :approval_cutoff => 5},
          {:id => "sq",    :name => "Albanian",      :approval_cutoff => 5},
          {:id => "kn",    :name => "Kannada",       :approval_cutoff => 5},
          {:id => "nv",    :name => "Navajo",        :approval_cutoff => 5},
          {:id => "chy",   :name => "Cheyenne",      :approval_cutoff => 5},
          {:id => "oj",    :name => "Ojibwa",       :approval_cutoff => 5},
          {:id => "bla",   :name => "Siksika",       :approval_cutoff => 5},
          {:id => "qu",    :name => "Quechua",       :approval_cutoff => 5},
          {:id => "wba",   :name => "Warao",         :approval_cutoff => 5},
          {:id => "lkt",   :name => "Lakota",        :approval_cutoff => 5},
          {:id => "mzk",   :name => "Nigeria Mambila", :approval_cutoff => 5},
          {:id => "id",    :name => "Indonesian",    :approval_cutoff => 5},
          {:id => "it",    :name => "Italian",       :approval_cutoff => 5},
          {:id => "nap",   :name => "Neapolitan",    :approval_cutoff => 5, :localizes_language_id => "it"},
          {:id => "lat",   :name => "Latin",         :approval_cutoff => 5},
          {:id => "tr",    :name => "Turkish",       :approval_cutoff => 5},
          {:id => "zun",   :name => "Zuni",          :approval_cutoff => 5},
          {:id => "ms",    :name => "Malay",         :approval_cutoff => 5},
          {:id => "zmw",   :name => "Mbo",           :approval_cutoff => 5},
          {:id => "sw",    :name => "Swahili",       :approval_cutoff => 5},
          {:id => "srn",   :name => "Sranan Tongo",  :approval_cutoff => 5},
          {:id => "ne",    :name => "Nepali",        :approval_cutoff => 5},
          {:id => "mg",    :name => "Malagasy",      :approval_cutoff => 5},
          {:id => "ru",    :name => "Russian",       :approval_cutoff => 5},
          {:id => "hil",   :name => "Hiligaynon",    :approval_cutoff => 5},
          {:id => "fij",   :name => "Fijian",        :approval_cutoff => 5},
          {:id => "haw",   :name => "Hawaiian",      :approval_cutoff => 5},
          {:id => "niu",   :name => "Niuean",        :approval_cutoff => 5},
          {:id => "pmy",   :name => "Papuan Malay",  :approval_cutoff => 5, :localizes_language_id => "ms"},
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
