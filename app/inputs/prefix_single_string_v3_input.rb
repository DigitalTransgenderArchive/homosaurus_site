class PrefixSingleStringV3Input < SingleBaseInput

  def uri_prefix
    vocab = template.instance_variable_get(:@vocab_id).to_s
    "https://homosaurus.org/#{vocab.match?(/\Av\d+\z/) ? vocab : 'v4'}/"
  end

  def inner_wrapper
    <<-HTML
          <li class="field-wrapper">
             <div class="input-group col-sm-12">
               <span class="input-group-addon">#{uri_prefix}</span>
              #{yield}
              </div>
          </li>
    HTML
  end

  def input_type
    #'multi_value'.freeze
    'no_repeat_field_value'.freeze
  end
end