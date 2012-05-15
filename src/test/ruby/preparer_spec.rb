require_relative '../../main/ruby/preparer'
require_relative 'test_helpers'
require_relative 'test_logger'
require 'tmpdir'

describe Preparer do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @templates = given_dir "#@sandbox/templates"
    @output = given_dir "#@sandbox/target"
    @logger = TestLogger.new

    @config = DeployConfig.new
    @config.maven_repository = "testdata/maven-repository"
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end


  def prepare!
    preparer = Preparer.new(@config, @output, @logger)
    preparer.logging = false
    preparer.build_all!
  end


  # Template basics

  it "creates an output directory for each server" do
    @config.server 'server1', 'server2' do
    end
    prepare!

    "#@output/server1".should be_a_directory
    "#@output/server2".should be_a_directory
  end

  it "empties the output directory if it already exists" do
    old_file = given_file "#@output/server1/old-file.txt"

    @config.server 'server1' do
    end
    prepare!

    old_file.should_not be_a_file
  end

  it "copies template files recursively to the server's output directory" do
    given_file "#@templates/example/file-from-template.txt"
    given_file "#@templates/example/subdir/file-from-template-subdir.txt"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/example"
    end
    prepare!

    "#@output/server1/file-from-template.txt".should be_a_file
    "#@output/server1/subdir/file-from-template-subdir.txt".should be_a_file
  end


  # Template inheritance

  it "copies parent template's files in addition to the child template's files" do
    given_file "#@templates/parent/parent-file.txt"
    given_file "#@templates/child/child-file.txt"
    given_file "#@templates/child/#{TemplateDir::CONFIG_FILE}", "{ :parent => '../parent' }"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/child"
    end
    prepare!

    "#@output/server1/child-file.txt".should be_a_file
    "#@output/server1/parent-file.txt".should be_a_file
  end

  it "child template's files override parent template's files" do
    given_file "#@templates/parent/overridden.txt", "from parent"
    given_file "#@templates/child/overridden.txt", "from child"
    given_file "#@templates/child/#{TemplateDir::CONFIG_FILE}", "{ :parent => '../parent' }"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/child"
    end
    prepare!

    IO.read("#@output/server1/overridden.txt").should == "from child"
  end

  it "doesn't copy the hidden template configuration file" do
    given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{}"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/example"
    end
    prepare!

    "#@output/server1/#{TemplateDir::CONFIG_FILE}".should_not be_a_file
  end

  it "copies normal hidden files" do
    given_file "#@templates/example/.some-other-hidden-file"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/example"
    end
    prepare!

    "#@output/server1/.some-other-hidden-file".should be_a_file
  end


  # Configuration files

  it "writes properties files to the server's output directory" do
    @config.server 'server1' do |server|
      server.with_properties_file 'lib/config.properties', {'some.key' => 'some value'}
    end
    prepare!

    properties_file = "#@output/server1/lib/config.properties"
    properties_file.should be_a_file
    IO.read(properties_file).should include('some.key=some value')
  end

  it "interpolates variables in filtered template files" do
    given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{ :filter => ['*.txt'] }"
    given_file "#@templates/example/answer.txt", 'answer = <%= answer %>'

    @config[:answer] = 42
    @config.server 'server1' do |server|
      server.based_on_template "#@templates/example"
    end
    prepare!

    IO.read("#@output/server1/answer.txt").should == 'answer = 42'
  end

  it "doesn't interpolate variables in non-filtered files" do
    given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{ :filter => ['*.a'] }"
    given_file "#@templates/example/filtered.a", 'answer = <%= answer %>'
    given_file "#@templates/example/non-filtered.b", 'answer = <%= answer %>'

    @config[:answer] = 42
    @config.server 'server1' do |server|
      server.based_on_template "#@templates/example"
    end
    prepare!

    IO.read("#@output/server1/filtered.a").should == 'answer = 42'
    IO.read("#@output/server1/non-filtered.b").should == 'answer = <%= answer %>'
  end


  # Maven artifacts

  it "by default, uses the default location of the local Maven repository" do
    config = DeployConfig.new

    config.maven_repository.should == "#{Dir.home}/.m2/repository"
  end

  it "copies WARs from the local Maven repository to the webapps directory" do
    given_file "#@templates/basic-webapp/#{TemplateDir::CONFIG_FILE}", "{ :webapps => 'webapps' }"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/basic-webapp"
      server.with_artifact :webapps, 'com.example:sample:1.0:war'
    end
    prepare!

    "#@output/server1/webapps/sample.war".should be_a_file
  end

  it "the webapps directory may be specified in a parent template" do
    given_file "#@templates/parent/#{TemplateDir::CONFIG_FILE}", "{ :webapps => 'webapps' }"
    given_file "#@templates/child/#{TemplateDir::CONFIG_FILE}", "{ :parent => '../parent' }"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/child"
      server.with_artifact :webapps, 'com.example:sample:1.0:war'
    end
    prepare!

    "#@output/server1/webapps/sample.war".should be_a_file
  end

  it "embeds JARs files from ZIP bundles inside WAR files" do
    given_file "#@templates/basic-webapp/#{TemplateDir::CONFIG_FILE}", "{ :webapps => 'webapps' }"

    @config.server 'server1' do |server|
      server.based_on_template "#@templates/basic-webapp"
      server.with_artifact :webapps, 'com.example:sample:1.0:war', ['com.example:extralibs:1.0:zip:bundle']
    end
    prepare!

    Zip.new("#@output/server1/webapps/sample.war").list.should include('WEB-INF/lib/extralibs-library.jar')
  end
end
