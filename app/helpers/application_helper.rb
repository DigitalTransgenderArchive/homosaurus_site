module ApplicationHelper

  def url_with_lang(lang)
    query = request.query_parameters.except("lang")
    query["lang"] = lang unless lang == fallback_locale
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  def canonical_url
    query = request.query_parameters.except("lang")
    "#{request.base_url}#{request.path}#{query.empty? ? "" : "?#{query.to_query}"}"
  end

  def lang_hidden_field
    hidden_field_tag(:lang, link_lang, id: nil) if link_lang
  end

  def button_to(*args, &block)
    index = block_given? ? 1 : 2
    html_options = args[index] || {}
    if link_lang && html_options[:method].to_s.downcase == "get"
      args[index] = html_options.merge(params: { lang: link_lang }.merge(html_options[:params] || {}))
    end
    super(*args, &block)
  end

  def hidden_email(email, reveal)
    if reveal
      return link_to email, "mailto:#{email}"
    else
      return link_to "[Click To Reveal Email]", "#", :onclick => "$('#captcha_form').submit(); return false;"
    end
  end
end