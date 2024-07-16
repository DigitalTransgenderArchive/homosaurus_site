class CreateTermRelationships < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?(:term_relationships)
      create_table :term_relationships, :id => false do |t|
        t.references :term,      null: false, foreign_key: true, index: true
        t.references :relation,  null: false, foreign_key: true
        t.references :language,               foreign_key: true, type: :string, collation: "utf8mb3_unicode_ci"
        t.text       :data
      end
    end

    unless TermRelationship.count() > 1
      say_with_time "Migrating descriptions and preferred labels" do
        Term.all().each do |t|
          if t.description != "" and t.description
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Description, :language_id => "en", :data => t.description)
            tr.save
          end
          pref_label = t.pref_label_language.nil? ? [t.pref_label] : t.pref_label_language.split("@")
          tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Pref_label,
                                       :language_id => pref_label.length > 1 ?
                                                         (case pref_label[1]
                                                          when "jpn" then "ja"
                                                          when "to" then "ton"
                                                          when "es" then "spa"
                                                          when "th" then "tha"
                                                          when "sm" then "smo"
                                                          when "hi" then "hil"
                                                          when "ch" then "chy"
                                                          else pref_label[1] end) :
                                                         'en', :data => pref_label[0])
          tr.save
        end
      end
      say_with_time "Migrating labels" do
        Term.where.not(labels_language: [""]).each do |t|
          t.labels_language.each do |t_label|
            t_label = t_label.split("@")
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Label,
                                         :language_id => t_label.length > 1 ?
                                                           (case t_label[1]
                                                            when "jpn" then "ja"
                                                            when "to" then "ton"
                                                            else t_label[1] end) :
                                                           'en', :data => t_label[0])
            tr.save
          end
        end
      end
      say_with_time "Migrating alt labels" do
        Term.where.not(alt_labels_language: [""]).each do |t|
          t.alt_labels_language.each do |t_alt_label|
            t_alt_label = t_alt_label.split("@")
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Alt_label,
                                         :language_id => t_alt_label.length > 1 ?
                                                           (case t_alt_label[1]
                                                            when "jpn" then "ja"
                                                            when "to" then "ton"
                                                            when "es" then "spa"
                                                            else t_alt_label[1] end) :
                                                           'en', :data => t_alt_label[0])
            tr.save
          end
        end
      end
      say_with_time "Migrating replacements/redirects" do
        ActiveRecord::Base.connection.execute("SELECT terms.id, t2.id, terms.visibility FROM `terms` JOIN terms as t2 on terms.is_replaced_by = t2.uri").each do |t|
          rel_id = (t[2] == "redirect") ? Relation::Redirects_to : Relation::Replaced_by
          tr = TermRelationship.create(:term_id => t[0], :relation_id => rel_id, :data => t[1])
          tr.save
        end
      end
      say_with_time "Migrating broader/narrower terms" do
        Term.where.not(narrower: [""]).each do |t|
          Term.where(uri: t.narrower).select("id, pref_label").each do |t_narrow|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Narrower, :data => t_narrow.id)
            tr.save
          end
        end
        Term.where.not(broader: [""]).each do |t|
          Term.where(uri: t.broader).select("id, pref_label").each do |t_broad|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Broader, :data => t_broad.id)
            tr.save
          end
        end
      end
      say_with_time "Migrating related term" do
        Term.where.not(related: [""]).each do |t|
          Term.where(uri: t.related).select("id, pref_label").each do |t_related|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Related, :data => t_related.id)
            tr.save
          end
        end
      end
      say_with_time "Migrating LCSH exact matches" do
        Term.where.not(exact_match_lcsh: [""]).each do |t|
          tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Lcsh_exact, :data => t.exact_match_lcsh[0])
          tr.save
        end
      end
      say_with_time "Migrating LCSH close matches" do
        Term.where.not(close_match_lcsh: [""]).each do |t|
          t.close_match_lcsh.each do |t_close_match|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Lcsh_close, :data => t_close_match)
            tr.save
          end
        end
      end
      say_with_time "Migrating Homosaurus exact matches" do
        Term.where.not(exact_match_homosaurus: [""]).each do |t|
          Term.where(uri: t.exact_match_homosaurus).select("id, pref_label").each do |t_exact_match|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Close_match, :data => t_exact_match.id)
            tr.save
          end
        end
      end
      say_with_time "Migrating Homosaurus close matches" do
        Term.where.not(close_match_homosaurus: [""]).each do |t|
          Term.where(uri: t.close_match_homosaurus).select("id, pref_label").each do |t_close_match|
            tr = TermRelationship.create(:term_id => t.id, :relation_id => Relation::Exact_match, :data => t_close_match.id)
            tr.save
          end
        end
      end
    end
  end

  def down
    drop_table :term_relationships
  end
end
