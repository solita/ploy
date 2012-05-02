require 'tmpdir'

class Zip

  def initialize(zip_file)
    @zip_file = File.absolute_path(zip_file)
  end

  def list
    get_output("jar tf \"#@zip_file\"").lines.map { |line| line.strip }
  end

  def add(file, subdir='')
    if subdir == ''
      # add to root of zip
      if File.directory?(file)
        src_dir = file
        src_file = "."
      else
        src_dir = File.dirname(file)
        src_file = File.basename(file)
      end
      update(@zip_file, src_dir, src_file)

    else
      # add to sub directory of zip
      Dir.mktmpdir { |work_dir|
        work_subdir = File.join(work_dir, subdir)
        FileUtils.mkdir_p(work_subdir)

        if File.directory?(file)
          FileUtils.cp_r(file+"/.", work_subdir)
        else
          FileUtils.cp(file, work_subdir)
        end

        update(@zip_file, work_dir, '.')
      }
    end
  end

  def unzip(target_dir)
    Dir.chdir(target_dir) {
      system("jar xf \"#@zip_file\"") or raise "unable to unzip #@zip_file to #{target_dir}"
    }
  end

  private

  def update(archive, change_dir, files_to_include)
    system("jar uf \"#{archive}\" -C \"#{change_dir}\" \"#{files_to_include}\"") or raise "unable to update #{archive} with #{files_to_include} in #{change_dir}"
  end

  def get_output(command)
    output = `#{command}"`
    raise "command failed: #{command}\n#{output}" unless $?.success?
    output
  end
end