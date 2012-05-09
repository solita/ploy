require_relative 'deploy_config'
require_relative 'preparer'
require 'optparse'

class CLI

  def initialize(args)
    @args = args
  end

  def run!()
    options = parse_options(@args)

    if options[:prepare]
      prepare(get(:config_file, options), get(:output_dir, options))
    end
  end

  private

  def parse_options(args)
    options = {}
    op = OptionParser.new do |opts|
      opts.banner = "Usage: deployer [options]"

      opts.on("--prepare", "Prepare installers") do
        options[:prepare] = true
      end

      opts.on("--config-file FILE", "Deployment configuration file") do |file|
        file = File.absolute_path(file)
        abort "No such file: #{file}" unless File.file? file
        options[:config_file] = file
      end

      opts.on("--output-dir DIR", "Output directory for the operations") do |dir|
        dir = File.absolute_path(dir)
        options[:output_dir] = dir
      end

      opts.on("--maven-repository DIR", "Location of local Maven repository where to find the artifacts", "Default: ~/.m2/repository") do |dir|
        dir = File.absolute_path(dir)
        abort "No such directory: #{dir}" unless File.directory? dir
        options[:maven_repository] = dir
      end
    end
    op.parse!(args)
    options
  end

  def get(key, options)
    unless options.has_key? key
      raise "Required parameter #{key} was missing: #{options.inspect}"
    end
    options[key]
  end


  # Commands

  def prepare(config_file, output_dir)
    config = DeployConfig.new
    Dir.chdir(File.dirname(config_file)) do
      eval(IO.read(config_file), get_binding_for_config_file(config), config_file)
    end

    preparer = Preparer.new(config, output_dir)
    preparer.build_all!
  end

  #noinspection RubyUnusedLocalVariable
  def get_binding_for_config_file(config)
    binding
  end
end
