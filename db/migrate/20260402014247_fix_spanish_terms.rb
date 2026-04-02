# coding: utf-8
require "csv"
class FixSpanishTerms < ActiveRecord::Migration[5.2]
  def up
    lang_id = "es"
    spanish_terms = Hash.new()

    # Parse CSV file
    csv_text = File.read("/data/railsApps/homosaurus_site/db/migrate/spanish_terms.csv")
    csv = CSV.parse(csv_text, headers: true, :col_sep => " | ", :quote_char => "§")

    # For each row in the CSV
    csv.each do |row|
      # Get term identifier
      id = row["Identifier"]

      # Get preferred label, alt labels, and description for the term
      if id and row["Translation prefLabel (Spanish)"]
        spanish_terms[id] = {
          Relation::Pref_label => row["Translation prefLabel (Spanish)"].strip,
          Relation::Alt_label => row["Translation altLabel (Spanish)"],
          Relation::Description => row["Description/Scope Note (Spanish)"]
        }
        if spanish_terms[id][Relation::Alt_label] and spanish_terms[id][Relation::Alt_label].include? "\\|"
          spanish_terms[id][Relation::Alt_label] = YAML.load(spanish_terms[id][Relation::Alt_label]).split("\\|\\| ").map{|t| t.strip}
        elsif !spanish_terms[id][Relation::Alt_label].nil? and !spanish_terms[id][Relation::Alt_label].empty?
          spanish_terms[id][Relation::Alt_label] = [spanish_terms[id][Relation::Alt_label]].map{|t| t.strip}
        else
          spanish_terms[id][Relation::Alt_label] = []
        end
      end
    end

    # Get latest release for vocabulary
    latest_release = Vocabulary.find_by(id: 4).latest_published_release.id

    pp "======== Fixing Translations========"
    vc = 1
    spanish_terms.reject!{|id, vals| Term.find_by(identifier: id).nil?}

    # For each term to fix
    spanish_terms.each do |id, vals|
      term = Term.find_by(identifier: id)
      #er = term.edit_requests.last

      pp "==== Translating #{vc}/#{spanish_terms.count} : #{term.identifier} ===="
      vc += 1

      # Create edit requests for the term
      er = EditRequest.new(:term_id => term.id,
                            :created_at => DateTime.now,
                            :version_release_id => latest_release,
                            :my_changes => EditRequest::makeChangeHash(term.visibility, term.uri, term.identifier),
                            :parent_id => nil, :status => "approved")
      er_change = EditRequest.new(:term_id => nil,
                                  :creator_id => nil,
                                  :created_at => DateTime.now,
                                  :version_release_id => nil,
                                  :status => "approved",
                                  :my_changes => EditRequest::makeChangeHash(term.visibility, term.uri, term.identifier),
                                  :parent_id => er.id)

      # Delete existing Spanish pref_label relationship
      term.term_relationships.where(relation_id: Relation::Pref_label, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Pref_label] << ["-", "es", tr.data]
      end

      # Delete existing Spanish alt_label relationships
      term.term_relationships.where(relation_id: Relation::Alt_label, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Alt_label] << ["-", "es", tr.data]
      end

      # Delete existing Spanish description
      term.term_relationships.where(relation_id: Relation::Description, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Description] << ["-", "es", tr.data]
      end

      # Create new Spanish pref_label relationship
      er.my_changes[Relation::Pref_label] << ["+", "es", vals[Relation::Pref_label]]
      er_change.my_changes[Relation::Pref_label] << ["+", "es", vals[Relation::Pref_label]]

      # Create new Spanish alt_label relationships
      vals[Relation::Alt_label].each do |al|
        if !al.nil? and !al.empty?
          er.my_changes[Relation::Alt_label] << ["+", "es", al]
          er_change.my_changes[Relation::Alt_label] << ["+", "es", al]
        end
      end

      # Create new Spanish description
      er.my_changes[Relation::Description] << ["+", "es", vals[Relation::Description]]
      er_change.my_changes[Relation::Description] << ["+", "es", vals[Relation::Description]]

      #pp er.my_changes.inspect
      er.save!
      er_change.save!
      er_change.update(parent_id: er.id)
    end
  end
end
