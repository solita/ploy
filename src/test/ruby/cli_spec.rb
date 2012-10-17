require_relative '../../main/ruby/cli'
require_relative 'test_helpers'
require_relative 'test_logger'

describe CLI do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @output = "#@sandbox/output"
    @logger = TestLogger.new
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  def run(*args)
    CLI.new(args, @logger, @logger).run!
  end

  it "can prepare a deployment configuration" do
    config = given_file "#@sandbox/config.rb", <<-eos
      config.server 'server1' do
      end
    eos

    run "prepare", "--config-file", config, "--output-dir", @output

    "#@output/server1".should be_a_directory
  end

  it "template paths are relative to the configuration file" do
    given_file "#@sandbox/templates/some-template/file-from-template.txt"
    config = given_file "#@sandbox/config.rb", <<-eos
      config.server 'server1' do |server|
        server.based_on_template 'templates/some-template'
      end
    eos

    run "prepare", "--config-file", config, "--output-dir", @output

    "#@output/server1/file-from-template.txt".should be_a_file
  end

  it "server configuration knows the location of the server's output directory" do
    config = given_file "#@sandbox/config.rb", <<-eos
      config.server 'server1' do |server|
        server.tasks[:task1] = proc do
          File.open(server.output_dir+"/result.txt", 'w') {}
        end
      end
    eos

    run "prepare", "task1", "--config-file", config, "--output-dir", @output

    "#@output/server1/result.txt".should be_a_file
  end

  it "the Maven repository can be configured on command line" do
    config = given_file "#@sandbox/config.rb", <<-eos
      File.open("#@sandbox/maven_repository.txt", 'w') do |file|
        file.write config.maven_repository
      end
    eos

    maven_repository_path = given_dir "#@sandbox/custom_maven_repository"
    run "dummytask", "--config-file", config, "--output-dir", @output, "--maven-repository", maven_repository_path

    IO.read("#@sandbox/maven_repository.txt").should == maven_repository_path
  end

  it "by default the local Maven repository's default location is used" do
    config = given_file "#@sandbox/config.rb", <<-eos
      File.open("#@sandbox/maven_repository.txt", 'w') do |file|
        file.write config.maven_repository
      end
    eos

    run "dummytask", "--config-file", config, "--output-dir", @output

    IO.read("#@sandbox/maven_repository.txt").should == File.join(Dir.home, ".m2/repository")
  end
end
