require 'rubygems'
gem 'rspec', '= 2.9.0'
require 'rspec'

RSpec::Matchers.define :be_a_file do
  match do |actual|
    File.exist?(actual)
  end
end

RSpec::Matchers.define :be_a_directory do
  match do |actual|
    Dir.exist?(actual)
  end
end

def given_file(path, content='')
  given_dir File.dirname(path)
  File.open(path, 'wb') { |file|
    file.write(content)
  }
  path.should be_a_file
  path
end

def given_dir(path)
  FileUtils.mkdir_p(path)
  path.should be_a_directory
  path
end
