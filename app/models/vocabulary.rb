class Vocabulary < ActiveRecord::Base
  require 'csv'
  has_many :terms
  has_many :version_releases

  def self.migrate_v1_from_dta
    voc = Vocabulary.find_by(identifier: "terms")
    if voc.blank?
      voc = Vocabulary.new
      voc.identifier = "terms"
      voc.name = "Homosaurus V1"
      voc.base_uri = "http://homosaurus.org/terms"
      voc.solr_model = "Homosaurus"
      voc.visibility = "visible"
      voc.version = "v1"
      voc.save!
    end

    ActiveRecord::Base.transaction do
      HomosaurusSubject.where(version: "v1").each do |subj|
        if Term.find_by(uri: subj.uri).blank?
          term = Term.new
          term.vocabulary_identifier = voc.identifier
          term.vocabulary = voc
          term.pid = subj.pid
          term.numeric_pid = subj.numeric_pid
          term.uri = subj.uri
          term.identifier = subj.identifier
          term.pref_label = subj.label
          term.pref_label_language = subj.prefLabel_language
          term.description = subj.description
          term.visibility = "visible"
          term.is_replaced_by = subj.isReplacedBy
          term.replaces = subj.replaces
          term.created_at = subj.created_at
          term.updated_at = subj.updated_at
          term.manual_update_date = subj.updated_at

          labels = []
          subj.language_labels.each do |lang_label|
            labels << lang_label.split('@')[0]
          end
          term.labels = labels
          term.labels_language = subj.language_labels

          term.alt_labels = subj.alt_labels
          term.alt_labels_language = subj.alt_labels

          broader_uris = []
          subj.broader.each do |broader|
            broader_uris << "http://homosaurus.org/terms/#{broader}"
          end
          term.broader = broader_uris

          narrower_uris = []
          subj.narrower.each do |narrower|
            narrower_uris << "http://homosaurus.org/terms/#{narrower}"
          end
          term.narrower = narrower_uris

          related_uris = []
          subj.related.each do |related|
            related_uris << "http://homosaurus.org/terms/#{related}"
          end
          term.related = related_uris

          term.close_match = subj.closeMatch
          term.exact_match = subj.exactMatch
          term.close_match_homosaurus = subj.closeMatch_homosaurus
          term.exact_match_homosaurus = subj.exactMatch_homosaurus
          closeMatch_lcsh_uris = []
          subj.closeMatch_lcsh.each do |lcsh|
            closeMatch_lcsh_uris << lcsh.uri
          end
          term.close_match_lcsh = closeMatch_lcsh_uris

          exactMatch_lcsh_uris = []
          subj.exactMatch_lcsh.each do |lcsh|
            exactMatch_lcsh_uris << lcsh.uri
          end
          term.exact_match_lcsh = exactMatch_lcsh_uris
          term.save!

        end
      end
    end
  end

  def self.migrate_v2_from_dta
    voc = Vocabulary.find_by(identifier: "v2")
    if voc.blank?
      voc = Vocabulary.new
      voc.identifier = "v2"
      voc.name = "Homosaurus V2"
      voc.base_uri = "http://homosaurus.org/v2"
      voc.solr_model = "HomosaurusV2"
      voc.visibility = "visible"
      voc.version = "v2"
      voc.save!
    end

    ActiveRecord::Base.transaction do
      HomosaurusV2Subject.where(version: "v2").each do |subj|
        if Term.find_by(uri: subj.uri).blank?
          term = Term.new
          term.vocabulary_identifier = voc.identifier
          term.vocabulary = voc
          term.pid = subj.pid
          term.numeric_pid = subj.numeric_pid
          term.uri = subj.uri
          term.identifier = subj.identifier
          term.pref_label = subj.label
          term.pref_label_language = subj.prefLabel_language
          term.description = subj.description
          term.visibility = "visible"
          term.is_replaced_by = subj.isReplacedBy
          term.replaces = subj.replaces
          term.created_at = subj.created_at
          term.updated_at = subj.updated_at
          term.manual_update_date = subj.updated_at

          labels = []
          subj.language_labels.each do |lang_label|
            labels << lang_label.split('@')[0]
          end
          term.labels = labels
          term.labels_language = subj.language_labels

          term.alt_labels = subj.alt_labels
          term.alt_labels_language = subj.alt_labels

          broader_uris = []
          subj.broader.each do |broader|
            broader_uris << "http://homosaurus.org/v2/#{broader}"
          end
          term.broader = broader_uris

          narrower_uris = []
          subj.narrower.each do |narrower|
            narrower_uris << "http://homosaurus.org/v2/#{narrower}"
          end
          term.narrower = narrower_uris

          related_uris = []
          subj.related.each do |related|
            related_uris << "http://homosaurus.org/v2/#{related}"
          end
          term.related = related_uris

          term.close_match = subj.closeMatch
          term.exact_match = subj.exactMatch
          term.close_match_homosaurus = subj.closeMatch_homosaurus
          term.exact_match_homosaurus = subj.exactMatch_homosaurus
          closeMatch_lcsh_uris = []
          subj.closeMatch_lcsh.each do |lcsh|
            closeMatch_lcsh_uris << lcsh.uri
          end
          term.close_match_lcsh = closeMatch_lcsh_uris

          exactMatch_lcsh_uris = []
          subj.exactMatch_lcsh.each do |lcsh|
            exactMatch_lcsh_uris << lcsh.uri
          end
          term.exact_match_lcsh = exactMatch_lcsh_uris
          term.save!

        end
      end
    end
  end

  def self.migrate_v3_from_dta
    voc = Vocabulary.find_by(identifier: "v3")
    if voc.blank?
      voc = Vocabulary.new
      voc.identifier = "v3"
      voc.name = "Homosaurus V3"
      voc.base_uri = "https://homosaurus.org/v3"
      voc.solr_model = "HomosaurusV3"
      voc.visibility = "visible"
      voc.version = "v3"
      voc.save!
    end

    ActiveRecord::Base.transaction do
      HomosaurusV3Subject.where(version: "v3").each do |subj|
        if Term.find_by(uri: subj.uri).blank?
          term = Term.new
          term.vocabulary_identifier = voc.identifier
          term.vocabulary = voc
          term.pid = subj.pid
          term.numeric_pid = subj.numeric_pid
          term.uri = subj.uri
          term.identifier = subj.identifier
          term.pref_label = subj.label
          term.pref_label_language = subj.prefLabel_language
          term.description = subj.description
          term.visibility = "visible"
          term.is_replaced_by = subj.isReplacedBy
          term.replaces = subj.replaces
          term.created_at = subj.created_at
          term.updated_at = subj.updated_at
          term.manual_update_date = subj.updated_at

          labels = []
          subj.language_labels.each do |lang_label|
            labels << lang_label.split('@')[0]
          end
          term.labels = labels
          term.labels_language = subj.language_labels

          term.alt_labels = subj.alt_labels
          term.alt_labels_language = subj.alt_labels

          broader_uris = []
          subj.broader.each do |broader|
            broader_uris << "https://homosaurus.org/v3/#{broader}"
          end
          term.broader = broader_uris

          narrower_uris = []
          subj.narrower.each do |narrower|
            narrower_uris << "https://homosaurus.org/v3/#{narrower}"
          end
          term.narrower = narrower_uris

          related_uris = []
          subj.related.each do |related|
            related_uris << "https://homosaurus.org/v3/#{related}"
          end
          term.related = related_uris

          term.close_match = subj.closeMatch
          term.exact_match = subj.exactMatch
          term.close_match_homosaurus = subj.closeMatch_homosaurus
          term.exact_match_homosaurus = subj.exactMatch_homosaurus
          closeMatch_lcsh_uris = []
          subj.closeMatch_lcsh.each do |lcsh|
            closeMatch_lcsh_uris << lcsh.uri
          end
          term.close_match_lcsh = closeMatch_lcsh_uris

          exactMatch_lcsh_uris = []
          subj.exactMatch_lcsh.each do |lcsh|
            exactMatch_lcsh_uris << lcsh.uri
          end
          term.exact_match_lcsh = exactMatch_lcsh_uris
          term.save!

        end
      end
    end
  end

  def fix_relationships
    # Handle Visible Case
    self.terms.where(visibility: 'visible').each do |current_term|
      # Fix broader
      current_term.broader.each do |broader|
        broader_term = Term.find_by(uri: broader)

        unless broader_term.narrower.include? current_term.uri
          broader_term.narrower += [current_term.uri]
          broader_term.save!
        end
      end

      # Fix narrower
      current_term.narrower.each do |narrower|
        narrower_term = Term.find_by(uri: narrower)

        unless narrower_term.broader.include? current_term.uri
          narrower_term.broader += [current_term.uri]
          narrower_term.save!
        end
      end

      # Fix related
      current_term.related.each do |related|
        related_term = Term.find_by(uri: related)

        unless related_term.related.include? current_term.uri
          related_term.related += [current_term.uri]
          related_term.save!
        end
      end
    end

    # Handle Redirect Case
    file = "#{Rails.root}/public/redirected_term_errors.csv"
    headers = ["Redirected_Term_URI", "URI_Of_Term_With_Reference", "Destination_Of_Redirected_Term"]
    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      self.terms.where(visibility: 'redirect').each do |current_term|
        # Fix broader
        current_term.broader.each do |broader|
          broader_term = Term.find_by(uri: broader)

          if broader_term.narrower.include? current_term.uri
            writer << [current_term.uri, broader_term.uri, current_term.is_replaced_by]
          end
        end

        # Fix narrower
        current_term.narrower.each do |narrower|
          narrower_term = Term.find_by(uri: narrower)

          if narrower_term.broader.include? current_term.uri
            writer << [current_term.uri, narrower_term.uri, current_term.is_replaced_by]
          end
        end

        # Fix related
        current_term.related.each do |related|
          related_term = Term.find_by(uri: related)

          if related_term.related.include? current_term.uri
            writer << [current_term.uri, related_term.uri, current_term.is_replaced_by]
          end
        end
      end
    end


    # Handle Deleted Case
    file = "#{Rails.root}/public/deleted_term_errors.csv"
    headers = ["Redirected_Term_URI", "URI_Of_Term_With_Reference"]

    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      self.terms.where(visibility: 'deleted').each do |current_term|
        # Fix broader
        current_term.broader.each do |broader|
          broader_term = Term.find_by(uri: broader)

          if broader_term.narrower.include? current_term.uri
            writer << [current_term.uri, broader_term.uri, current_term.is_replaced_by]
          end
        end

        # Fix narrower
        current_term.narrower.each do |narrower|
          narrower_term = Term.find_by(uri: narrower)

          if narrower_term.broader.include? current_term.uri
            writer << [current_term.uri, narrower_term.uri, current_term.is_replaced_by]
          end
        end

        # Fix related
        current_term.related.each do |related|
          related_term = Term.find_by(uri: related)

          if related_term.related.include? current_term.uri
            writer << [current_term.uri, related_term.uri, current_term.is_replaced_by]
          end
        end
      end
    end

  end
end  