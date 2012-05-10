require_relative '../../main/ruby/cli'
require_relative 'test_helpers'

describe CLI do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @output = "#@sandbox/target"
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  def run(*args)
    CLI.new(args).run!
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
        server.use_template 'templates/some-template'
      end
    eos

    run "prepare", "--config-file", config, "--output-dir", @output

    "#@output/server1/file-from-template.txt".should be_a_file
  end
end
