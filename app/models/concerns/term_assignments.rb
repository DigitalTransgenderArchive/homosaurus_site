module TermAssignments
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
    value = clean_values(value)
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
    values.each do |val|
      if val.class == String
        if val.include?('@')
          lang_check = val.split('@').last
          if lang_check == 'en-GB' || lang_check == 'en-US' || ISO_639.find_by_code(lang_check).present?
            r << val
          end
        end
      else
        raise 'Unhandled Labels Language Term assignment for: ' + val.class.to_s
      end
    end
    lbls = []
    r.each do |val|
      lbls << val.split('@').first
    end
    self.labels = lbls
    value = r
    super
  end

  def alt_labels_language=(value)
    r = []
    values = clean_values(value)
    values.each do |val|
      if val.class == String
        if val.include?('@')
          lang_check = val.split('@').last
          if lang_check == 'en-GB' || lang_check == 'en-US' || ISO_639.find_by_code(lang_check).present?
            r << val
          end
        end
      else
        raise 'Unhandled Alt Labels Language Term assignment for: ' + val.class.to_s
      end
    end
    lbls = []
    r.each do |val|
      lbls << val.split('@').first
    end
    self.alt_labels = lbls
    value = r
    super
  end

end