class PrefixMultiSelectV3Input < MultiSelectInput

  def uri_prefix
    vocab = template.instance_variable_get(:@vocab_id).to_s
    "https://homosaurus.org/#{vocab.match?(/\Av\d+\z/) ? vocab : 'v4'}/"
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
    html_options[:class] += ["#{input_dom_id} form-control multi-text-field duplicateable term-link-field"]
    html_options[:'aria-labelledby'] = label_id
    html_options[:name] += "[data]"
    html_options[:list] = "homosaurus-term-list"
    html_options[:autocomplete] = "off"
    @rendered_first_element = true
    pair = Array(value)
    shown = term_identifiers[pair[1].to_s] || pair[0].to_s[/\A\S+/]
    out = template.text_field_tag(attribute_name, shown, html_options)
    out << template.hidden_field_tag("term[#{attribute_name}][][language_id]", nil)
    unless template.instance_variable_get(:@homosaurus_term_list_rendered)
      template.instance_variable_set(:@homosaurus_term_list_rendered, true)
      out << template.content_tag(:datalist, template.safe_join(select_options.map { |text, _id| template.content_tag(:option, text.to_s.sub(/\A\S+\s*\(/, "").chomp(")"), value: text.to_s[/\A\S+/]) }), id: "homosaurus-term-list")
    end
    out
  end

  def term_identifiers
    @term_identifiers ||= select_options.map { |text, id| [id.to_s, text.to_s[/\A\S+/]] }.to_h
  end

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
             <span class="input-group-addon">#{uri_prefix}</span>
              #{yield}

              <span class="input-group-btn regular_audits_duplicate_span">
                <button class="btn btn-success" data-js-duplicate-audits-field="true" type="button">+</button>
              </span>
              <span class="input-group-btn">
                 <button class="btn btn-danger" data-js-delete-audits-field="true" type="button">-</button>
              </span>
              </div>
          </li>
    HTML
  end
  # def collection
  #   @collection = attribute_name.split("_")[1]
  # end
  def input(wrapper_options)
    @collection = options[:collection]
    @collection2 = options[:collection2]
    super
  end
  def collection
    @collection.empty? ? ['', nil] : @collection
  end
  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      if !@rendered_first_element && value.blank?
        buffer << yield(value, index)
      elsif value.present?
        term = Term.find_by(id: value[1])
        if term
          buffer << yield(["#{term.identifier} (#{term.pref_label})", term.id], index) unless @rendered_first_element && value.blank?
        else
          buffer << yield(['', nil], index) unless @rendered_first_element && value.blank?
        end
      end
    end
  end
end
