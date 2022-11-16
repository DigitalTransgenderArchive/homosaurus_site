module TermAssignments
  require 'languages'

  def clean_values(value)
    case value.class.to_s
    when 'String'
      return [value]
    when 'Array'
      return value.uniq
    when 'Integer'
      return [value.to_s]
    when '' # nil case
      return []
    else
      return [value]
    end
  end

  def pref_label_language=(value)
    if value.include?('@')
      lang_check = value.split('@').last
      unless lang_check == 'en-GB' || lang_check == 'en-US' || ISO_639.find_by_code(lang_check).present?
        value = value.split('@').first
      end
    end

    self.pref_label = value.split('@').first
    super
  end

  def labels_language=(value)
    r = []
    values = clean_values(value)
    if values.present? && values.size > 1 && values[0].class == String
      values.sort!
    end
    values.each do |val|
      if val.class == String
        if val.include?('@')
          lang_check = val.split('@').last
          if lang_check == 'en-GB' || lang_check == 'en-US' || ISO_639.find_by_code(lang_check).present? || Languages[lang_check.to_sym].present?
            r << val
          end
        else
          r << val
        end
      else
        raise 'Unhandled Labels Language Term assignment for: ' + val.class.to_s
      end
    end
    self.labels = r.map { |lbl| lbl.split('@')[0] }
    value = r
    super
  end

  def alt_labels_language=(value)
    r = []
    values = clean_values(value)
    if values.present? && values.size > 1 && values[0].class == String
      values.sort!
    end
    values.each do |val|
      if val.class == String
        if val.include?('@')
          lang_check = val.split('@').last
          if lang_check == 'en-GB' || lang_check == 'en-US' || ISO_639.find_by_code(lang_check).present?
            r << val
          end
        else
          r << val
        end
      else
        raise 'Unhandled Alt Labels Language Term assignment for: ' + val.class.to_s
      end
    end
    # lbls = []
    # r.each do |val|
    #  lbls << val.split('@').first
    # end
    self.alt_labels = r.map { |lbl| lbl.split('@')[0] }
    value = r
    super
  end

  def exact_match_lcsh=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
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
        r << val
        raise "Could not find lcsh for: #{val.to_s}" if r.last.nil?
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

  def close_match_lcsh=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
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
        r << val
        raise "Could not find lcsh for: #{val.to_s}" if r.last.nil?
      else
        raise 'Unhandled GenericObject assignment for: ' + val.class.to_s
      end
    end
    value = r
    super
  end

end