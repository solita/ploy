def assert_type(name, value, type)
  unless value.kind_of? type
    raise "#{name}'s type must be #{type}, but was #{value.class.name}"
  end
end

class DeployConfig

  PARENT_REF = '.parent'
  WEBAPPS_TAG = '.webapps'

  attr_reader :template_replacements,
              :servers

  attr_accessor :maven_repository

  def initialize()
    @template_replacements = {}
    @servers = []
    @maven_repository = File.join(Dir.home, '.m2/repository')
  end

  def []=(key, value)
    assert_type(:key, key, Symbol)
    @template_replacements[key] = value
  end

  def server(*hostnames)
    hostnames.each { |hostname|
      assert_type(:hostname, hostname, String)

      server_config = ServerConfig.new(hostname)
      yield server_config
      @servers << server_config
    }
  end
end

class ServerConfig

  attr_reader :hostname,
              :tasks,
              :template,
              :properties_files,
              :webapps

  def initialize(hostname)
    @hostname = hostname
    @tasks = {}
    @template = nil
    @properties_files = {}
    @webapps = {}
  end

  def use_template(source_path)
    assert_type(:source_path, source_path, String)
    @template = File.absolute_path(source_path)
  end

  def use_properties(target_path, properties)
    assert_type(:target_path, target_path, String)
    assert_type(:properties, properties, Hash)
    @properties_files[target_path] = properties
  end

  def install_webapp(webapp, jar_bundles = [])
    assert_type(:webapp, webapp, String)
    assert_type(:jar_bundles, jar_bundles, Array)
    @webapps[webapp] = jar_bundles
  end
end
