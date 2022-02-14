class SingleSelectInput < SingleBaseInput

  private

  def select_options
    @select_options ||= begin
      collection = options.delete(:collection) || self.class.boolean_collection
      collection.respond_to?(:call) ? collection.call : collection.to_a
    end
  end

  def build_field(value, _index)
    html_options = input_html_options.dup

    if @rendered_first_element
      html_options[:id] = nil
      html_options[:required] = nil
    else
      html_options[:id] ||= input_dom_id
    end
    html_options[:class] ||= []
    html_options[:class] += ["#{input_dom_id} singleton form-control multi-text-field"]
    html_options[:'aria-labelledby'] = label_id
    @rendered_first_element = true

    html_options.merge!(options.slice(:include_blank))
    template.select_tag(attribute_name, template.options_for_select(select_options, value), html_options)
  end

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      if  value.blank? and !@rendered_first_element
        buffer << yield(value, index)
      elsif value.present?
        if value.class.name == "String"
          buffer << yield([value, value], index)
        else
          #if value.respond_to?('uri')
            #buffer << yield([value.uri, value.label], index)
          #else
            #buffer << yield([value.label, value.label], index)
          #end
          buffer << yield([value.label, value.label], index)
        end
      end
    end
  end
end
