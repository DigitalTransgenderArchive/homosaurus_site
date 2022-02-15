class Repo
  def self.blazegraph_config
    @blazegraph_config ||= YAML::load(File.open(Repo.blazegraph_config_path))[Settings.env]
                               .with_indifferent_access
  end

  def self.blazegraph_config_path
    File.join(Settings.app_root, 'config', 'blazegraph.yml')
  end

  def self.connection
    @repo ||= ::RDF::Blazegraph::Repository.new(uri: Repo.blazegraph_config[:url])
  end

  def self.qskos value
    if value.match(/^sh\d+/)
      return ::RDF::URI.new("http://id.loc.gov/authorities/subjects/#{value}")
    else
      return ::RDF::URI.new("http://www.w3.org/2004/02/skos/core##{value}")
    end
  end

end
