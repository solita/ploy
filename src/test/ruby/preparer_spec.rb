require_relative 'test_helpers'
require_relative '../../main/ruby/deploy_config'
require_relative '../../main/ruby/preparer'
require 'tmpdir'

describe Preparer do

  before(:each) do
    @sandbox = Dir.mktmpdir()
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  it "creates an output directory for each server" do
    config = DeployConfig.new
    config.server 'server1', 'server2' do |server|
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    File.join(@sandbox, 'server1').should be_a_directory
    File.join(@sandbox, 'server2').should be_a_directory
  end

  it "empties the output directory if it already exists" do
    old_file = File.join(@sandbox, 'server1/old-file.txt')
    FileUtils.mkdir_p(File.dirname(old_file))
    FileUtils.touch(old_file)
    old_file.should be_a_file

    config = DeployConfig.new
    config.server 'server1' do |_|
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    old_file.should_not be_a_file
  end

  it "copies template files recursively to the server's output directory" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_template 'testdata/sample-template'
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    File.join(@sandbox, 'server1/file-from-template.txt').should be_a_file
    File.join(@sandbox, 'server1/subdir/file-from-template-subdir.txt').should be_a_file
  end

  it "copies parent template's files in addition to the child template's files" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_template 'testdata/child-template'
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    File.join(@sandbox, 'server1/child-file.txt').should be_a_file
    File.join(@sandbox, 'server1/parent-file.txt').should be_a_file
  end

  it "child template's files override parent template's files" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_template 'testdata/child-template'
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    IO.read(File.join(@sandbox, 'server1/overridden.txt')).strip.should == "child"
  end

  it "doesn't copy the hidden parent reference file" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_template 'testdata/child-template'
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    File.join(@sandbox, 'server1', DeployConfig::PARENT_REF).should_not be_a_file
  end

  it "copies other hidden files" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_template 'testdata/child-template'
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    File.join(@sandbox, 'server1/.some-other-hidden-file').should be_a_file
  end

  it "writes properties files to the server's output directory" do
    config = DeployConfig.new
    config.server 'server1' do |server|
      server.use_properties 'lib/config.properties', {'some.key' => 'some value'}
    end

    preparer = Preparer.new(config, @sandbox)
    preparer.build_all!

    properties_file = File.join(@sandbox, 'server1/lib/config.properties')
    properties_file.should be_a_file
    IO.read(properties_file).should include('some.key=some value')
  end
end
