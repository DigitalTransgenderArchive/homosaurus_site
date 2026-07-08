class MeiMultiLookupInput < MultiBaseInput

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'repeat_field_value'.freeze
  end

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              <span class="input-group-btn regular_audits_duplicate_span">
                <button class="btn btn-success" data-js-duplicate-audits-field="true" type="button", tabindex="-1">+</button>
              </span>
              <span class="input-group-btn">
                 <button class="btn btn-danger" data-js-delete-audits-field="true" type="button", tabindex="-1">-</button>
              </span>
              </div>
          </li>
    HTML
  end

  def build_field(value, index)
    options = build_field_options(value == "" ? "" : value[1], index)
    options[:class] += ["duplicateable"]
    out = ""
    if options.delete(:type) == 'textarea'.freeze
      out << @builder.text_area(attribute_name, options)
    else
      out << @builder.text_field(attribute_name, options)
    end
    new_options = build_field_options(value == "" ? "" : value[0], index, true)
    disabled_langs = Language.where(supported: true).where.not(id: I18n.locale).pluck(:id)
    #out << @builder.select("#{attribute_name}", Language.all().pluck(:name, :id), {}, new_options)
    if disabled_langs.include?(value[0])
      new_options[:disabled] = true
    end
    new_options[:class] += ["form-select"]
    out << template.select_tag(attribute_name, template.options_for_select(
                                 Language.order('supported desc', 'name asc').pluck(:name, :id),
                                 selected: value[0],
                                 disabled: Language.where(supported: true).where.not(id: I18n.locale).pluck(:id)
                               ), new_options)
    out
  end

  def collection
    @collection.empty? ? ['', nil] : @collection
  end  

end
