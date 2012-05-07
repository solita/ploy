require_relative '../../main/ruby/main'
require_relative 'test_helpers'

describe Main do

  before(:each) do
    @sandbox = Dir.mktmpdir()
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  def run(*args)
    Main.new(args).run!
  end

  it "can prepare a deployment configuration" do
    config = given_file "#@sandbox/config.rb", <<-eos
      config.server 'server1' do
      end
    eos
    target = "#@sandbox/target"

    run "prepare", config, target

    "#{target}/server1".should be_a_directory
  end
end
