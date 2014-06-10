require_relative 'template_dir'

def assert_type(name, value, type)
  unless value.kind_of? type
    raise "#{name}'s type must be #{type}, but was #{value.class.name}"
  end
end

class DeployConfig

  attr_reader :output_dir,
              :variables,
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

      server_config = ServerConfig.new(self, hostname)
      yield server_config
      @servers << server_config
    }
  end
end

class ServerConfig

  attr_reader :deploy_config,
              :hostname,
              :output_dir,
              :variables,
              :tasks,
              :template,
              :files,
              :webapps

  def initialize(deploy_config, hostname)
    @deploy_config = deploy_config
    @hostname = hostname
    @output_dir = File.join(deploy_config.output_dir, hostname)
    @variables = {}.merge(deploy_config.variables)
    @tasks = {}.merge(deploy_config.default_tasks)
    @template = nil
    @files = []
    @webapps = []
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

  def with_text_file(target_path, content)
    assert_type(:target_path, target_path, String)
    assert_type(:content, content, String)
    @files << [target_path, content]
  end

  def with_properties_file(target_path, properties)
    assert_type(:target_path, target_path, String)
    assert_type(:properties, properties, Hash)
    with_text_file(target_path, properties.map { |key, value| "#{key}=#{value}\n" }.join)
  end

  # TODO: add with_copied_artifact
  # TODO: add with_unzipped_artifact

  def with_repacked_war_artifact(target_dir, war_artifact, jar_bundles = [])
    assert_type(:target_dir, target_dir, String)
    assert_type(:war_artifact, war_artifact, String)
    assert_type(:jar_bundles, jar_bundles, Array)
    @webapps << [target_dir, war_artifact, jar_bundles]
  end
end
