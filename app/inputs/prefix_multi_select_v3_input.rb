class PrefixMultiSelectV3Input < MultiSelectInput

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
             <span class="input-group-addon">https://homosaurus.org/v3/</span>
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

  def buffer_each(collection)
    collection.each_with_object('').with_index do |(value, buffer), index|
      if !@rendered_first_element && value.blank?
        buffer << yield(value, index)
      elsif value.present?
        term = Term.find_by(uri: value)
        buffer << yield(["#{term.identifier} (#{term.pref_label})", term.uri], index) unless @rendered_first_element && value.blank?
      end
    end
  end

end