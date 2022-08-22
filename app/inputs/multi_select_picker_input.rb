class MultiSelectPickerInput < MultiSelectInput

  private

  def build_field(value, _index)
    html_options = input_html_options.dup
    @rendered_first_element = true

    html_options[:class] ||= []
    html_options[:class] += ["#{input_dom_id} form-control user-picker duplicateable"]
    html_options[:data] ||= {}

    html_options[:data][:endpoint] = html_options[:endpoint]
    html_options[:data][:placeholder] = html_options[:placeholder]

    html_options[:data][:"js-select-picker"] = true
    html_options[:data][:"no-clear"] = options[:no_clear]

    html_options[:data][:param1] = html_options[:param1]
    html_options[:data][:param2] = html_options[:param2]
    html_options[:data][:param1] ||= ''
    html_options[:data][:param2] ||= ''

    if value.present?
      html_options[:data][:initial] = value[0]
    end
    #html_options[:"data-select2-tags"] = '[{"id": "1", "text": "One"}]'
    #html_options[:"data-data"] = '[{"id": "1", "text": "One"}]'
    #html_options[:"data-tags"] = 'true'
    
    html_options.merge!(options.slice(:include_blank))
    # second param is the selected option... may want to try that over the JS...
    template.select_tag(attribute_name, template.options_for_select(select_options(value)), html_options)
  end

  def select_options(value)
    if value.present?
      @select_options = [[value[1], value[0]]]
    else
      @select_options ||= begin
        collection = options.delete(:collection) || self.class.boolean_collection
        collection.respond_to?(:call) ? collection.call : collection.to_a
      end
    end
  end

end
