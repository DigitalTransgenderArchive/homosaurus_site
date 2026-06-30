#!/usr/bin/env ruby

# Usage:
#   rails runner update_to_v5.rb

require 'csv'

changes = []
errors = []
langs = ["de","es","es_rev","fr","ja","nl","sv"]

langs.each do |lang_id|
    terms = Hash.new()
    csv_text = File.read(lang_id + ".csv")
    if lang_id == "es_rev"
      lang_id = "es"
    end
    csv = CSV.parse(csv_text, headers: true, :col_sep => "\t", :quote_char => '§')
    csv.each do |row|
      id = row["identifier"]
      if id and row["prefLabel"]
        terms[id] = {
          Relation::Pref_label => row["prefLabel"].strip,
          Relation::Alt_label => row["altLabel"],
          Relation::Description => row["description"],
          Relation::History_note => row["historyNote"]
        }
        if terms[id][Relation::Alt_label] and terms[id][Relation::Alt_label].include? "||"
          terms[id][Relation::Alt_label] = YAML.load(terms[id][Relation::Alt_label]).split("||").map{|t| t.strip}
        elsif !terms[id][Relation::Alt_label].nil? and !terms[id][Relation::Alt_label].empty?
          terms[id][Relation::Alt_label] = [terms[id][Relation::Alt_label]].map{|t| t.strip}
        else
          terms[id][Relation::Alt_label] = []
        end
      end
    end

    latest_release = Vocabulary.find_by(id: 4).version_releases.find_by(status: "Pending").id
    #pp Vocabulary.find_by(id: 4).version_releases.find_by(status: "Pending")

    pp "======== Adding New Translations ========"
    vc = 1
    terms.reject!{|id, vals| Term.find_by(identifier: id).nil?}

    terms.take(1).each do |id, vals|
    #terms.each do |id, vals|
      term = Term.find_by(identifier: id)

      pp "==== Translating #{vc}/#{terms.count} to #{lang_id}: #{term.identifier} ===="
      vc += 1
      #er = term.edit_requests.last
      #er.delete_children
      #er.delete
      #exit
      er = EditRequest.new(:term_id => term.id,
                           :created_at => DateTime.now,
                           :version_release_id => latest_release,
                           :my_changes => EditRequest::makeChangeHash(term.visibility, term.uri, term.identifier),
                           :parent_id => nil, :status => "approved")
    
      er_change = EditRequest.new(:term_id => nil,
                                  :creator_id => 29,
                                  :created_at => DateTime.now,
                                  :version_release_id => nil,
                                  :status => "approved",
                                  :my_changes => EditRequest::makeChangeHash(term.visibility, term.uri, term.identifier),
                                  :parent_id => er.id)

      # Delete existing pref_label relationship
      term.term_relationships.where(relation_id: Relation::Pref_label, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Pref_label] << ["-", lang_id, tr.data]
      end

      # Delete existing alt_label relationships
      term.term_relationships.where(relation_id: Relation::Alt_label, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Alt_label] << ["-", lang_id, tr.data]
      end

      # Delete existing description
      term.term_relationships.where(relation_id: Relation::Description, language_id: lang_id).each do |tr|
        er.my_changes[Relation::Description] << ["-", lang_id, tr.data]
      end

      # Delete existing history note
      term.term_relationships.where(relation_id: Relation::History_note, language_id: lang_id).each do |tr|
        er.my_changes[Relation::History_note] << ["-", lang_id, tr.data]
      end

      # Create new pref_label relationship
      er.my_changes[Relation::Pref_label] << ["+", lang_id, vals[Relation::Pref_label]]
      er_change.my_changes[Relation::Pref_label] << ["+", lang_id, vals[Relation::Pref_label]]

      # Create new alt_label relationships
      vals[Relation::Alt_label].each do |al|
        if !al.nil? and !al.empty?
          er.my_changes[Relation::Alt_label] << ["+", lang_id, al]
          er_change.my_changes[Relation::Alt_label] << ["+", lang_id, al]
        end
      end

      # Create new description
      if !vals[Relation::Description].nil? and !vals[Relation::Description].empty?
        er.my_changes[Relation::Description] << ["+", lang_id, vals[Relation::Description]]
        er_change.my_changes[Relation::Description] << ["+", lang_id, vals[Relation::Description]]
      end

      # Create new history note
      if !vals[Relation::History_note].nil? and !vals[Relation::History_note].empty?
        er.my_changes[Relation::History_note] << ["+", lang_id, vals[Relation::History_note]]
        er_change.my_changes[Relation::History_note] << ["+", lang_id, vals[Relation::History_note]]
      end

      #pp er.my_changes.inspect
      reviewer = User.find_by!(id: 29)
      VoteStatus.create!(
        votable: er,
        reviewer_id: reviewer.id,
        language_id: I18n.locale,
        status: "approved",
      )
      er.save!
      er_change.save!
      er_change.update(parent_id: er.id)
    end
end