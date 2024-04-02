class MultiSelectInput < MultiBaseInput

  private

  def select_options
    @select_options ||= begin
                          #collection = options.delete(:collection2) || options.delete(:collection) || self.class.boolean_collection
      collection = @collection2
      #collection = Term.where(vocabulary_identifier: params[:vocab_id]).order("lower(pref_label) ASC").map{|t| [t.identifier + "(" + term.pref_label + ")", term.id]}
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
    html_options[:class] += ["#{input_dom_id} form-control multi-text-field duplicateable form-select"]
    html_options[:'aria-labelledby'] = label_id
    html_options[:name] += "[data]"
    @rendered_first_element = true
    
    html_options.merge!(options.slice(:include_blank))
    out = template.select_tag(attribute_name, template.options_for_select(select_options, value), html_options)
    out << template.hidden_field_tag("term[#{attribute_name}][][language_id]", nil)
    out
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
          if value.respond_to?('label')
            buffer << yield([value.label, value.label], index)
          elsif value.respond_to?('title') and value.respond_to?('pid')
            buffer << yield([value.title, value.pid], index)
          else
            raise 'Cannot set value :('
          end
        end
      end
    end
  end
end
