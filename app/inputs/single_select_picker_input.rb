class SingleSelectPickerInput < MultiSelectPickerInput

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'no_repeat_field_value'.freeze
  end

  private

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
              #{yield}
              </div>
          </li>
    HTML
  end
end