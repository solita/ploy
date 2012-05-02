require_relative 'test_helpers'
require_relative '../../main/ruby/zip'
require 'tmpdir'

describe Zip do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    zip_file = File.join(@sandbox, 'sample.zip')
    FileUtils.cp('testdata/sample.zip', zip_file)
    @zip = Zip.new(zip_file)
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end


  it "lists files from a ZIP" do
    @zip.list.should == ['sample.txt']
  end

  it "adds a file to a ZIP" do
    file = create_file(@sandbox, 'file.txt')

    @zip.add(file)

    @zip.list.include?('file.txt').should be_true
  end

  it "adds a file to a ZIP, into a subdirectory" do
    file = create_file(@sandbox, 'file.txt')

    @zip.add(file, "WEB-INF/lib")

    @zip.list.include?('WEB-INF/lib/file.txt').should be_true
  end

  it "adds contents of a directory to a ZIP" do
    dir = File.join(@sandbox, 'dir')
    create_file(dir, 'file1.txt')
    create_file(dir, 'file2.txt')

    @zip.add(dir)

    @zip.list.include?('file1.txt').should be_true
    @zip.list.include?('file2.txt').should be_true
  end

  it "adds contents of a directory to a ZIP, into a subdirectory" do
    dir = File.join(@sandbox, 'dir')
    create_file(dir, 'file1.txt')
    create_file(dir, 'file2.txt')

    @zip.add(dir, "WEB-INF/lib")

    @zip.list.include?('WEB-INF/lib/file1.txt').should be_true
    @zip.list.include?('WEB-INF/lib/file2.txt').should be_true
  end

  it "unzips a ZIP to a target dir" do
    @target_dir = File.join(@sandbox, 'target')
    Dir.mkdir(@target_dir)

    @zip.unzip(@target_dir)

    File.join(@target_dir, 'sample.txt').should be_a_file
  end

  private

  def create_file(dir, file)
    file = File.join(dir, file)
    FileUtils.mkdir_p(File.dirname(file))
    File.open(file, 'w') { |f| f.write('') }
    file
  end
end