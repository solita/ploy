require 'java'
java_import Java::FiSolitaPloy::ZipUtil

class Zip

  def initialize(zip_file)
    @zip_file = File.absolute_path(zip_file)
  end

  def list
    ZipUtil.list(@zip_file).to_a
  end

  def add(file, subdir='/')
    ZipUtil.add(@zip_file, file, subdir)
  end

  def unzip(target_dir)
    ZipUtil.unzip(@zip_file, target_dir)
  end
end
