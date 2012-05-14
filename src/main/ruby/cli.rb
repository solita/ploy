require_relative 'deploy_config'
require_relative 'preparer'
require_relative 'task_executor'
require 'optparse'

class CLI

  def initialize(args)
    @args = args
  end

  def run!()
    options = parse_options(@args)
    config_file = options[:config_file]
    output_dir = options[:output_dir]
    tasks = options[:tasks]

    config = DeployConfig.new
    prepare_task = proc do |server|
      preparer = Preparer.new(config, output_dir)
      preparer.build_server!(server)
    end
    config.default_tasks = {:prepare => prepare_task}

    Dir.chdir(File.dirname(config_file)) do
      eval(IO.read(config_file), get_binding_for_config_file(config), config_file)
    end

    listener = DummyListener.new # TODO
    executor = TaskExecutor.new(config, listener)
    executor.execute(tasks)
  end

  private

  def parse_options(args)
    options = {:tasks => []}
    op = OptionParser.new do |opts|
      opts.banner = "Usage: deployer [OPTION]... TASK..."
      opts.separator "Runs the TASKs of the deployment configuration, in the specified order."
      opts.separator "The built-in task 'prepare' generates files from templates to the output directory."

      opts.separator ""
      opts.separator "Required"

      opts.on("--config-file FILE", String, "Deployment configuration file") do |file|
        file = File.absolute_path(file)
        abort "No such file: #{file}" unless File.file? file
        options[:config_file] = file
      end

      opts.on("--output-dir DIR", String, "Output directory for files generated from templates") do |dir|
        dir = File.absolute_path(dir)
        options[:output_dir] = dir
      end

      opts.separator ""
      opts.separator "Optional"

      opts.on("--maven-repository DIR", String, "Location of the local Maven repository where to find any artifacts", "Default: ~/.m2/repository") do |dir|
        dir = File.absolute_path(dir)
        abort "No such directory: #{dir}" unless File.directory? dir
        options[:maven_repository] = dir
      end

      opts.on_tail("-h", "--help", "Display this help and exit") do
        puts opts
        exit 1
      end
    end

    if args.empty?
      args << "--help"
    end

    begin
      op.parse!(args)
      options[:tasks] += args.map { |s| s.to_sym }

      raise OptionParser::MissingArgument.new("TASKS") if options[:tasks].empty?
      raise MissingOption.new("--config-file") if options[:config_file].nil?
      raise MissingOption.new("--output-dir") if options[:output_dir].nil?

    rescue OptionParser::ParseError
      $stderr.puts "Error: " + $!.to_s
      exit 1
    end

    options
  end

  class MissingOption < OptionParser::ParseError
    const_set(:Reason, 'missing option'.freeze)
  end

  #noinspection RubyUnusedLocalVariable
  def get_binding_for_config_file(config)
    binding
  end
end

class DummyListener # TODO
  def task_succeeded(hostname, task)
  end

  def task_failed(hostname, task, exception)
  end

  def task_skipped(hostname, task)
  end
end
