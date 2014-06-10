# This configuration file is Ruby code, so we can use for example local variables
sample_version = '1.0'

# We can use replacement variables to fill in values in the templates
config[:some_variable] = 'foo'
config[:another_variable] = 'bar'

# Each call to the `config.server` method declares a set of similar servers.
# You can give it as a parameter the names of one or more servers, and a code
# block which configures each of those servers.
config.server 'server1', 'server2' do |server|

  # Server specific configuration files are generated based on templates.
  # Each template should have in its base directory a `.template.rb` file,
  # which may declare e.g. parent templates and the files which are filtered
  # for replacement variables.
  server.based_on_template 'templates/generic-server'

  # You can generate arbitrary files by just specifying the file name and content
  server.with_text_file 'lib/dynamically-generated.txt', "the file content\n"

  # There is special support for generating Java .properties files from a Ruby map
  server.with_properties_file 'lib/dynamically-generated.properties', {
          'someKey' => 'some value'
  }

  # These is special support for WAR files.
  # - The first parameter is the path to the directory where to copy the WAR file.
  # - The second parameter is a Maven artifact descriptor for the WAR file. It will be
  #   copied from the local Maven repository.
  # - (optional) The third parameter is an array of Maven artifact descriptors of ZIP
  #   files which will be unpacked and their contents copied inside the WAR's
  #   /WEB-INF/lib directory.
  server.with_webapp 'webapps-dir', "com.example:sample:#{sample_version}:war", ["com.example:extralibs:#{sample_version}:zip:bundle"]

  # You can have multiple tasks, each identified by a unique name (here :deploy).
  # There is also a built-in :prepare task which processes the template files and
  # writes them to the output directory. The order in which the tasks are executed
  # is defined on the command line.
  server.tasks[:deploy] = proc do
    # This closure can contain any code necessary to deploy your application
    puts "Running the deploy task for #{server.hostname}"
    puts "We can get the prepared configuration files from #{server.output_dir}"
  end

  # We can use also server specific replacement variables
  server[:tomcat_home] = "/opt/tomcat"
end
