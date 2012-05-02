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
