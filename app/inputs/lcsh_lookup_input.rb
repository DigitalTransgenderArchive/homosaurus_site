class LcshLookupInput < MultiSelectInput

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
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
    pp "THE COLLECTION IS -> #{collection}"
    collection.each_with_object('').with_index do |(value, buffer), index|
      pp "VA IS -> #{value}"
      if !@rendered_first_element && value.blank?
        buffer << yield(value, index)
      elsif value.present?
        term = LcshSubjectCache.find_by(uri: value[1])
        if term
          buffer << yield(["#{term.label} (#{term.uri})", term.uri], index) unless @rendered_first_element && value.blank?
        else
          buffer << yield(['', nil], index) unless @rendered_first_element && value.blank?
        end
      end
    end
  end
end
