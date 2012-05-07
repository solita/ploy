require_relative 'test_helpers'
require_relative '../../main/ruby/deploy_config'
require_relative '../../main/ruby/preparer'
require 'tmpdir'

describe Preparer do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @templates = given_dir "#@sandbox/templates"
    @target = given_dir "#@sandbox/target"
    @config = DeployConfig.new
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  def given_file(path, content='')
    given_dir File.dirname(path)
    File.open(path, 'wb') { |file|
      file.write(content)
    }
    path
  end

  def given_dir(path)
    FileUtils.mkdir_p(path)
    path
  end

  def prepare!
    preparer = Preparer.new(@config, @target)
    preparer.build_all!
  end

  it "creates an output directory for each server" do
    @config.server 'server1', 'server2' do |server|
    end
    prepare!

    "#@target/server1".should be_a_directory
    "#@target/server2".should be_a_directory
  end

  it "empties the output directory if it already exists" do
    old_file = given_file "#@target/server1/old-file.txt"

    @config.server 'server1' do |server|
    end
    prepare!

    old_file.should_not be_a_file
  end

  it "copies template files recursively to the server's output directory" do
    given_file "#@templates/example/file-from-template.txt"
    given_file "#@templates/example/subdir/file-from-template-subdir.txt"

    @config.server 'server1' do |server|
      server.use_template "#@templates/example"
    end
    prepare!

    "#@target/server1/file-from-template.txt".should be_a_file
    "#@target/server1/subdir/file-from-template-subdir.txt".should be_a_file
  end

  it "copies parent template's files in addition to the child template's files" do
    given_file "#@templates/parent/parent-file.txt"
    given_file "#@templates/child/child-file.txt"
    given_file "#@templates/child/#{DeployConfig::PARENT_REF}", "../parent\n"

    @config.server 'server1' do |server|
      server.use_template "#@templates/child"
    end
    prepare!

    "#@target/server1/child-file.txt".should be_a_file
    "#@target/server1/parent-file.txt".should be_a_file
  end

  it "child template's files override parent template's files" do
    given_file "#@templates/parent/overridden.txt", "from parent"
    given_file "#@templates/child/overridden.txt", "from child"
    given_file "#@templates/child/#{DeployConfig::PARENT_REF}", "../parent\n"

    @config.server 'server1' do |server|
      server.use_template "#@templates/child"
    end
    prepare!

    IO.read("#@target/server1/overridden.txt").should == "from child"
  end

  it "doesn't copy the hidden parent reference file" do
    given_dir "#@templates/parent"
    given_file "#@templates/child/#{DeployConfig::PARENT_REF}", "../parent\n"

    @config.server 'server1' do |server|
      server.use_template "#@templates/child"
    end
    prepare!

    "#@target/server1/#{DeployConfig::PARENT_REF}".should_not be_a_file
  end

  it "copies other hidden files" do
    given_file "#@templates/example/.some-other-hidden-file"

    @config.server 'server1' do |server|
      server.use_template "#@templates/example"
    end
    prepare!

    "#@target/server1/.some-other-hidden-file".should be_a_file
  end

  it "writes properties files to the server's output directory" do
    @config.server 'server1' do |server|
      server.use_properties 'lib/config.properties', {'some.key' => 'some value'}
    end
    prepare!

    properties_file = "#@target/server1/lib/config.properties"
    properties_file.should be_a_file
    IO.read(properties_file).should include('some.key=some value')
  end
end
