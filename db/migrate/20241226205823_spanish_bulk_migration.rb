# coding: utf-8
require 'csv'
class SpanishBulkMigration < ActiveRecord::Migration[5.2]
  # Reads the given CSV file, uses it to add spanish translations to v4
  def up
    new_spanish_terms = Hash.new()
    csv_text = File.read('/data/railsApps/homosaurus_site/db/migrate/spanish_terms.csv')
    csv = CSV.parse(csv_text, headers: true)
    csv.each do |row|
      id = row["Identifier"]
      if id and row["Translation prefLabel (Spanish)"]
        new_spanish_terms[id] = {Relation::Pref_label => row["Translation prefLabel (Spanish)"].strip,
                                 Relation::Alt_label => row["Translation altLabel (Spanish)"],
                                 Relation::Description => row["Description/Scope Note (Spanish)"],
                                 Relation::History_note => row["historyNote (Spanish)"]
                                }
        if new_spanish_terms[id][Relation::Alt_label] and new_spanish_terms[id][Relation::Alt_label].include? "||"
          new_spanish_terms[id][Relation::Alt_label] = YAML.load(new_spanish_terms[id][Relation::Alt_label]).split("|| ").map{|t| t.strip}
        elsif !new_spanish_terms[id][Relation::Alt_label].nil?
          new_spanish_terms[id][Relation::Alt_label] = [new_spanish_terms[id][Relation::Alt_label]].map{|t| t.strip}
        else
          new_spanish_terms[id][Relation::Alt_label] = []
        end
      end
    end
    vocab = Vocabulary.find_by(id: 3).terms.where(visibility: "visible")
    pp "======== Updating Identifiers ========"
    vc = 1
    vocab.each do |term|
      uri = "https://homosaurus.org/v4/#{term.identifier}"
      pp "==== Updating #{vc}/#{vocab.count} : #{term.identifier} : #{uri} ===="
      vc += 1
      er = EditRequest.new(:term_id => term.id,
                           :created_at => DateTime.now,
                           :version_release_id => VersionRelease.last.id,
                           :my_changes => EditRequest::makeChangeHash(term.visibility, uri, term.identifier),
                           :parent_id => nil, :status => "approved")
      er_change = EditRequest.new(:term_id => nil,
                                  :creator_id => nil,
                                  :created_at => DateTime.now,
                                  :version_release_id => nil,
                                  :status => "approved",
                                  :my_changes => EditRequest::makeChangeHash(term.visibility, uri, term.identifier),
                                  :parent_id => er.id)
      er.save!
      er_change.save!
      er_change.update(parent_id: er.id)
    end
    pp "======== Adding Translations========"
    vc = 1
    new_spanish_terms.reject!{|id, vals| Term.find_by(identifier: id).nil?}

    new_spanish_terms.each do |id, vals|
      term = Term.find_by(identifier: id)
      er = term.edit_requests.last
      pp "==== Translating #{vc}/#{new_spanish_terms.count} : #{term.identifier} : #{er.my_changes['uri']} ===="
      vc += 1
      er_change = EditRequest.new(:term_id => nil,
                                  :creator_id => nil,
                                  :created_at => DateTime.now,
                                  :version_release_id => nil,
                                  :status => "approved",
                                  :my_changes => EditRequest::makeChangeHash(term.visibility, er.my_changes['uri'], id),
                                  :parent_id => er.id)
      er.my_changes[Relation::Pref_label] << ["+", "es", vals[Relation::Pref_label]]
      er_change.my_changes[Relation::Pref_label] << ["+", "es", vals[Relation::Pref_label]]

      er.my_changes[Relation::Description] << ["+", "es", vals[Relation::Description]]
      er_change.my_changes[Relation::Description] << ["+", "es", vals[Relation::Description]]

      contrib_note = "Traducción y revisión al español realizadas por Ernesto Cuba, Sofia Zamora, Sandy Alcantara, Mar Munné, Ana Portnoy Brimmer y el Comité Español de Homosaurus en 2024"
      er.my_changes[Relation::Contributors] << ["+", "es", contrib_note]
      er_change.my_changes[Relation::Contributors] << ["+", "es", contrib_note]

      if vals[Relation::History_note]
        er.my_changes[Relation::History_note] << ["+", "es", vals[Relation::History_note]]
        er_change.my_changes[Relation::History_note] << ["+", "es", vals[Relation::History_note]]
      end

      vals[Relation::Alt_label].each do |al|
        er.my_changes[Relation::Alt_label] << ["+", "es", al]
        er_change.my_changes[Relation::Alt_label] << ["+", "es", al]
      end
      er.save!
      er_change.save!
      er_change.update(parent_id: er.id)
    end
  end
end
