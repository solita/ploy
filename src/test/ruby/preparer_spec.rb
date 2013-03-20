require_relative '../../main/ruby/preparer'
require_relative 'test_helpers'
require_relative 'test_logger'
require 'tmpdir'

def permission_bits(file)
  sprintf('%o', File.stat(file).mode)
end

describe Preparer do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @templates = given_dir "#@sandbox/templates"
    @output = given_dir "#@sandbox/output"
    @logger = TestLogger.new

    @config = DeployConfig.new(@output)
    @config.maven_repository = "testdata/maven-repository"
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end


  def prepare!
    preparer = Preparer.new(@config, @logger)
    preparer.logging = false
    preparer.build_all!
  end


  describe "Output directory" do

    it "is created for each server" do
      @config.server 'server1', 'server2' do
      end
      prepare!

      "#@output/server1".should be_a_directory
      "#@output/server2".should be_a_directory
    end

    it "is emptied if it already exists" do
      old_file = given_file "#@output/server1/old-file.txt"

      @config.server 'server1' do
      end
      prepare!

      old_file.should_not be_a_file
    end
  end

  describe "Copying template files" do

    it "copied recursively to the server's output directory" do
      given_file "#@templates/example/file-from-template.txt"
      given_file "#@templates/example/subdir/file-from-template-subdir.txt"

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
      end
      prepare!

      "#@output/server1/file-from-template.txt".should be_a_file
      "#@output/server1/subdir/file-from-template-subdir.txt".should be_a_file
    end

    it "copied from parent and child templates" do
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

    it "the template configuration file is not copied" do
      given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{}"

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
      end
      prepare!

      "#@output/server1/#{TemplateDir::CONFIG_FILE}".should_not be_a_file
    end

    it "hidden files are copied" do
      given_file "#@templates/example/.hidden-file"

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
      end
      prepare!

      "#@output/server1/.hidden-file".should be_a_file
    end

    it "copied files retain their permission bits" do
      original = "#@templates/example/custom-perm.txt"
      given_file original
      File.chmod(0755, original)

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
      end
      prepare!

      permission_bits("#@output/server1/custom-perm.txt").should == permission_bits(original)
    end
  end

  describe "Dynamically created files" do

    it "can generate properties files from hashes" do
      @config.server 'server1' do |server|
        server.with_properties_file 'lib/config.properties', {'some.key' => 'some value'}
      end
      prepare!

      properties_file = "#@output/server1/lib/config.properties"
      properties_file.should be_a_file
      IO.read(properties_file).should include('some.key=some value')
    end
  end

  describe "Variable interpolation" do

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

    it "server variables can be read through the server" do
      server_variable = nil

      @config.server 'server1' do |server|
        server[:answer] = 42
        server_variable = server[:answer]
      end

      server_variable.should == 42
    end

    it "common variables can be read through the server" do
      server_variable = nil
      @config[:answer] = 42

      @config.server 'server1' do |server|
        server_variable = server[:answer]
      end

      server_variable.should == 42
    end

    it "common variables cannot be modified through the server" do
      @config[:answer] = 42

      @config.server 'server1' do |server|
        server[:answer] = 100
      end

      @config.variables[:answer].should == 42
    end

    it "server variables override the common variables" do
      given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{ :filter => ['*.txt'] }"
      given_file "#@templates/example/answer.txt", 'answer = <%= answer %>'

      @config[:answer] = 42
      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
        server[:answer] = 100
      end
      prepare!

      IO.read("#@output/server1/answer.txt").should == 'answer = 100'
    end

    it "interpolated files retain their permission bits" do
      given_file "#@templates/example/#{TemplateDir::CONFIG_FILE}", "{ :filter => ['*.sh'] }"
      original = "#@templates/example/script.sh"
      given_file original, "unimportant content"
      File.chmod(0755, original)

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/example"
      end
      prepare!

      permission_bits("#@output/server1/script.sh").should == permission_bits(original)
    end
  end

  describe "Maven artifacts" do

    it "by default, uses the default location of the local Maven repository" do
      config = DeployConfig.new(@output)

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

    it "repacked WAR files retain their permission bits" do
      given_file "#@templates/basic-webapp/#{TemplateDir::CONFIG_FILE}", "{ :webapps => 'webapps' }"
      original = "testdata/maven-repository/com/example/sample/1.0/sample-1.0.war"

      @config.server 'server1' do |server|
        server.based_on_template "#@templates/basic-webapp"
        server.with_artifact :webapps, 'com.example:sample:1.0:war', ['com.example:extralibs:1.0:zip:bundle']
      end
      prepare!

      permission_bits("#@output/server1/webapps/sample.war").should == permission_bits(original)
    end
  end
end
