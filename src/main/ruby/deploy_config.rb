class DeployConfig

  PARENT_REF = '.parent'
  WAR_LOCATION = '.war_location'

  attr_reader :template_replacements,
              :servers

  attr_accessor :maven_repository

  def initialize()
    @template_replacements = {}
    @servers = {}
    @maven_repository = File.join(Dir.home, '.m2/repository')
  end

  def []=(key, value)
    @template_replacements[key] = value
  end

  def server(*hostnames)
    server_config = ServerConfig.new
    yield server_config

    hostnames.each { |hostname|
      @servers[hostname] = server_config
    }
  end
end

class ServerConfig

  attr_reader :template,
              :properties_files,
              :webapps

  def initialize()
    @properties_files = {}
    @webapps = {}
  end

  def use_template(source_path)
    @template = source_path
  end

  def use_properties(target_path, properties)
    @properties_files[target_path] = properties
  end

  def install_webapp(webapp, manuscripts = [])
    @webapps[webapp] = manuscripts
  end
end
