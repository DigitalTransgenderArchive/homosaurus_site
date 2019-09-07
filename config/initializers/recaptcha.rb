Recaptcha.configure do |config|
  config.site_key  = Settings.recaptcha_site_key
  config.secret_key = Settings.recaptcha_secret_key
end