class LcshLookupInput < MeiMultiLookupInput

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//) || value.blank?
      #if value.uri.match(/http:\/\/id.loc.gov\/authorities\/subjects\//)
      if  value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present?
          l = LcshSubjectCache.find_by(uri: value)
          buffer << yield("#{l.label} (#{l.uri})", index)
      end
    end
  end
end
