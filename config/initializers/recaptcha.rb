Recaptcha.configure do |config|
  config.site_key  = Settings.recaptcha_site_key
  config.secret_key = Settings.recaptcha_secret_key
  if Settings.dta_config["proxy_host"].present?
    config.proxy = "http://#{Settings.homosaurus_config['proxy_host']}:#{Settings.homosaurus_config['proxy_port']}"
  end
end