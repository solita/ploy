class DeployConfig

  PARENT_REF = '.parent'

  attr_accessor :template_replacements,
                :servers

  def initialize()
    @template_replacements = {}
    @servers = {}
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

  attr_accessor :template,
                :properties_files

  def initialize()
    @properties_files = {}
  end

  def use_template(source_path)
    @template = source_path
  end

  def use_properties(target_path, properties)
    @properties_files[target_path] = properties
  end

  def install_war(war, manuscripts = [])
  end
end
