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
end
