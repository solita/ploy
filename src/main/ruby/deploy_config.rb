require_relative 'template_dir'

def assert_type(name, value, type)
  unless value.kind_of? type
    raise "#{name}'s type must be #{type}, but was #{value.class.name}"
  end
end

class DeployConfig

  attr_reader :variables,
              :servers

  attr_accessor :maven_repository,
                :default_tasks

  def initialize(output_dir)
    @output_dir = output_dir
    @variables = {}
    @servers = []
    @maven_repository = File.join(Dir.home, '.m2/repository')
    @default_tasks = {}
  end

  def []=(key, value)
    assert_type(:key, key, Symbol)
    @variables[key] = value
  end

  def server(*hostnames)
    hostnames.each { |hostname|
      assert_type(:hostname, hostname, String)

      server_output_dir = File.join(@output_dir, hostname)
      server_config = ServerConfig.new(hostname, server_output_dir, @variables, @default_tasks)
      yield server_config
      @servers << server_config
    }
  end
end

class ServerConfig

  attr_reader :hostname,
              :output_dir,
              :variables,
              :tasks,
              :template,
              :properties_files,
              :webapps

  def initialize(hostname, output_dir, shared_variables, default_tasks)
    @hostname = hostname
    @output_dir = output_dir
    @variables = {}.merge(shared_variables)
    @tasks = {}.merge(default_tasks)
    @template = nil
    @properties_files = {}
    @webapps = {}
  end

  def [](key)
    @variables[key]
  end

  def []=(key, value)
    assert_type(:key, key, Symbol)
    @variables[key] = value
  end

  def based_on_template(source_path)
    assert_type(:source_path, source_path, String)
    @template = TemplateDir.new(File.absolute_path(source_path))
  end

  def with_properties_file(target_path, properties)
    assert_type(:target_path, target_path, String)
    assert_type(:properties, properties, Hash)
    @properties_files[target_path] = properties
  end

  def with_artifact(location_tag, webapp, jar_bundles = [])
    assert_type(:webapp, webapp, String)
    assert_type(:jar_bundles, jar_bundles, Array)
    raise "for now, :webapps is the only supported location tag" if location_tag != :webapps
    @webapps[webapp] = jar_bundles
  end
end
