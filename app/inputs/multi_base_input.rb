class MultiBaseInput < SimpleForm::Inputs::CollectionInput
  include WithLabelOptions

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'repeat_field_value'.freeze
  end

  def input(wrapper_options)
    @rendered_first_element = false
    input_html_classes.unshift("string")
    input_html_options[:name] ||= "#{object_name}[#{attribute_name}][]"

    outer_wrapper do
      buffer_each(collection) do |value, index|
        inner_wrapper do
          build_field(value, index)
        end
      end
    end
  end

  protected

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      buffer << yield(value, index) unless @rendered_first_element && value.blank?
    end
  end

  def outer_wrapper
    "    <ul class=\"listing\">\n        #{yield}\n      </ul>\n"
  end


  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              <span class="input-group-btn regular_audits_duplicate_span">
                <button class="btn btn-success" data-js-duplicate-audits-field="true" type="button" tabindex="-1">+</button>
              </span>
              <span class="input-group-btn">
                 <button class="btn btn-danger" data-js-delete-audits-field="true" type="button" tabindex="-1">-</button>
              </span>
              </div>
          </li>
    HTML
  end

  private

  # Although the 'index' parameter is not used in this implementation it is useful in an
  # an overridden version of this method, especially when the field is a complex object and
  # the override defines nested fields.
  def build_field_options(value, index)
    options = input_html_options.dup

    options[:value] = value
    if @rendered_first_element
      #options[:id] = nil
      options[:id] ||= input_dom_id #FIXME: Snould update javascript to use something other than id...
      options[:required] = nil
    else
      options[:id] ||= input_dom_id
    end
    options[:class] ||= []
    options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    options[:'aria-labelledby'] = label_id
    @rendered_first_element = true

    options
  end

  def build_field(value, index)
    options = build_field_options(value, index)
    options[:class] += ["duplicateable"]
    if options.delete(:type) == 'textarea'.freeze
      @builder.text_area(attribute_name, options)
    else
      @builder.text_field(attribute_name, options)
    end
  end

  def label_id
    input_dom_id + '_label'
  end

  def input_dom_id
    input_html_options[:id] || "#{object_name}_#{attribute_name}"
  end

  def collection
=begin
    if attribute_name.to_s == 'alt_titles'
      raise 'Got Here ' + object.send(attribute_name).to_s
    end
=end
    if object.present?
      @collection ||= Array.wrap(object.send(attribute_name)).reject { |value| value.to_s.strip.blank? } + ['']
    else
      ['']
    end
  end

  def multiple?; true; end
end
