class LcshSubjectCache < ActiveRecord::Base
  self.table_name = "lcsh_subject_cache"

  serialize :alt_labels, Array
  serialize :broader, Array
  serialize :narrower, Array
  serialize :related, Array
  # Caches header given url
  def self.add_new(val)
    ld = LcshSubjectCache.find_by(uri: val)
    if ld.blank?
        english_label = nil
        default_label = nil
        any_match = nil
        full_alt_term_list = []

        if Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).count > 0
          # Get prefLabel
          Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('prefLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              if result_statement.object.language == :en
                english_label ||= result_statement.object.value
              elsif result_statement.object.language.blank?
                default_label ||= result_statement.object.value
                full_alt_term_list << result_statement.object.value
              else
                any_match ||= result_statement.object.value
                #FIXME
                full_alt_term_list << result_statement.object.value
              end
            end
          end

          full_alt_term_list -= [default_label] if english_label.blank? && default_label.present?
          full_alt_term_list -= [any_match] if english_label.blank? && default_label.blank? && any_match.present?

          default_label ||= any_match
          english_label ||= default_label

          # Get alt labels
          Repo.connection.query(:subject=>::RDF::URI.new(val), :predicate=>Repo.qskos('altLabel')).each_statement do |result_statement|
            #LoC has blank nodes... see alts of http://id.loc.gov/authorities/subjects/sh85102696 ... these aren't literals.
            #LoC's blank node representation.... alt: to_s == "_:t829213" or check .resource? or check .node? or .id == 't829213'
            if result_statement.object.literal?
              full_alt_term_list << result_statement.object.value
            end
          end
          full_alt_term_list.uniq!

          #TODO: Broader? Narrower? Etc?
          ld = LcshSubjectCache.create(uri: val, label: english_label, alt_labels: full_alt_term_list)
        else
          raise "Could not find lcsh for prefLabel for: #{val.to_s}"
        end
    end
    return ["#{ld.uri.split('/')[-1]} (#{ld.label})", ld.uri]
  end
end
