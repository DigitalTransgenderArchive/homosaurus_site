module WithLabelOptions
  def label(wrapper_options = nil)
    if input_html_options[:include_checkbox]
      label_options = merge_wrapper_options(label_html_options, wrapper_options)

      add_checkbox do
        if generate_label_for_attribute?
          "#{@builder.label(label_target, label_text, label_options)} #{link_to_help}"
        else
          "#{template.label_tag(nil, label_text, label_options)} #{link_to_help}"
        end
      end
    else
      "#{super} #{link_to_help}"
    end
  end

  def add_checkbox
    checkbox_label = input_html_options[:include_checkbox]
    checkbox_label ||= "Missing Checkbox Label"
    checkbox_checked = 'checked' if input_html_options[:checkbox_checked]
    checkbox_checked ||= ''
    <<-HTML
    <div style="float:left">
        #{yield}
    </div>
    <div style="float:right;">
       <div class="input boolean optional #{input_dom_id}_checkbox_div">
        <input class="boolean optional" type="checkbox" value="true" name="#{object_name}[#{attribute_name}_checkbox]" id="#{object_name}_#{attribute_name}_checkbox" #{checkbox_checked}>
        <label class="boolean optional" for="#{object_name}_#{attribute_name}_checkbox">#{checkbox_label}</label>
       </div>
     </div>
     <div style="clear:both"></div>
    HTML
  end

  def link_to_help
    if input_html_options[:include_help]
      template.link_to '#', :"data-turbolinks" => false, rel: 'popover'.freeze, class: 'popover_link',
                       'data-toggle' => "popover", 'data-trigger' => 'focus',
                       'tabindex' => '-1', # See https://github.com/angular-ui/bootstrap/issues/3687
                       'title' => help_label, 'data-content' => help_content,
                       'data-placement' => 'right', 'data-turbolinks'=> 'false' do
        template.content_tag 'i', nil, "aria-hidden" => true, class: "glyphicon glyphicon-question-sign", style: 'padding-top:2px;'
      end
    end
  end

  def help_content
    input_html_options[:include_help] || attribute_name.to_s.humanize
  end

  def help_label
    input_html_options[:help_label] || default_aria_label
  end

  def default_aria_label
    attribute_name.to_s.humanize
    #I18n.t("#{i18n_scope}.aria_label.#{lookup_model_names.join('.')}.default",
           #title: attribute_name.to_s.humanize)
  end
end
