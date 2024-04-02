class PreflanguageLabelsMeiInput < MeiMultiLookupInput
  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              </div>
          </li>
    HTML
  end
  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      #buffer << yield(value, index) if value.match(/http:\/\/id.loc.gov\/authorities\/subjects\//) || value.blank?
      #if value.uri.match(/http:\/\/id.loc.gov\/authorities\/subjects\//)
      if  value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present?
          buffer << yield(value, index)
      end
    end
  end
end
