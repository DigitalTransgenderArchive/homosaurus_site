class Settings

  def self.solr_url
    @solr_url ||= Settings.solr_config["url"]
    raise "url in blacklight.yml could not be detected" if @solr_url.blank?
    @solr_url
  end

  def self.solr_config
    @solr_config ||= YAML.load_file(File.join(Rails.root, "config", "solr.yml"))[Rails.env.to_s]
    raise "blacklight yml file seems to not exist" if @solr_config.nil?
    @solr_config
  end

  def self.homosaurus_config
    @homosaurus_config ||= YAML.load_file(File.join(Rails.root, "config", "homosaurus.yml"))[Rails.env.to_s]
    raise "Dta configuration yml file seems to not exist" if @homosaurus_config.nil?
    @homosaurus_config
  end

  def self.app_root
    return @app_root if @app_root
    @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
    @app_root ||= APP_ROOT if defined?(APP_ROOT)
    @app_root ||= '.'
  end

  def self.env
    return @env if @env
    #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
    #@env = ENV["RAILS_ENV"] = "test" if ENV
    @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
    @env ||= 'development'
  end


  def self.google_analytics_id
    @google_analytics_id ||= Settings.homosaurus_config["google_analytics_id"]
  end

end
