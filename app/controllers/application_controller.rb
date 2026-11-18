class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :redirect_locale_subdomain
  around_action :switch_locale
  helper_method :url_lang, :link_lang, :fallback_locale

  def switch_locale(&action)
    locale = url_lang || subdomain_locale || test_subdomain_locale || accept_language_locale || I18n.default_locale
    response.headers["Vary"] = [response.headers["Vary"], "Accept-Language"].compact.join(", ")
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    link_lang ? { lang: link_lang } : {}
  end

  def url_lang
    @url_lang = supported_locale(params[:lang]) unless defined?(@url_lang)
    @url_lang
  end

  def link_lang
    url_lang unless url_lang == fallback_locale
  end

  def fallback_locale
    @fallback_locale ||= (subdomain_locale || test_subdomain_locale || accept_language_locale || I18n.default_locale).to_s
  end

  private

  def supported_locale(code)
    code = code.to_s.downcase
    I18n.available_locales.map(&:to_s).include?(code) ? code : nil
  end

  def subdomain_locale
    supported_locale(request.subdomains.first)
  end

  def test_subdomain_locale
    request.subdomains.first == "test" ? "es" : nil
  end

  def accept_language_locale
    ranked = request.headers["Accept-Language"].to_s.split(",").each_with_index.map do |entry, position|
      tag, *options = entry.strip.split(";").map(&:strip)
      quality = options.find { |option| option.start_with?("q=") }
      [tag.to_s.split("-").first, quality ? quality.delete_prefix("q=").to_f : 1.0, position]
    end
    ranked.reject { |_, quality, _| quality <= 0 }
          .sort_by { |_, quality, position| [-quality, position] }
          .map { |code, _, _| supported_locale(code) }
          .compact
          .first
  end

  def redirect_locale_subdomain
    locale = subdomain_locale
    return unless locale && (request.get? || request.head?)
    host = request.host.sub(/\A#{locale}\./i, "")
    query = request.query_parameters.merge("lang" => url_lang || locale).to_query
    redirect_to "#{request.protocol}#{host}#{request.port_string}#{request.path}?#{query}", status: :moved_permanently
  end
end
