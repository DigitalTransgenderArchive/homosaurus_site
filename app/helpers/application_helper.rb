module ApplicationHelper

  def hidden_email(email, reveal)
    if reveal
      return link_to email, "mailto:#{email}"
    else
      return link_to "[Click To Reveal Email]", "#", :onclick => "$('#captcha_form').submit(); return false;"
    end
  end
end