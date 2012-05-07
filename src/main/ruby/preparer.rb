require 'pathname'
require_relative 'template'

class Preparer

  def initialize(config, output_dir)
    @config = config
    @output_dir = output_dir
  end

  def build_all!
    @config.servers.each { |hostname, server|
      output_dir = File.join(@output_dir, hostname)
      FileUtils.rm_rf(output_dir)
      FileUtils.mkdir_p(output_dir)
      build_server!(output_dir, server)
    }
  end

  private

  def build_server!(output_dir, server)
    template_dir = server.template
    if template_dir
      copy_template(template_dir, output_dir)
    end

    server.properties_files.each { |relative_path, properties|
      output_file = File.join(output_dir, relative_path)
      write_properties_file(properties, output_file)
    }
  end

  def copy_template(template_dir, output_dir)
    parent_ref = File.join(template_dir, DeployConfig::PARENT_REF)
    if File.exist?(parent_ref)
      parent_dir = File.join(template_dir, IO.read(parent_ref).strip)
      copy_template(parent_dir, output_dir)
    end

    Dir.glob("#{template_dir}/**/*", File::FNM_DOTMATCH).
            reject { |file| special_file?(file) }.
            each { |file| copy_template_file(template_dir, file, output_dir) }
  end

  def special_file?(file)
    basename = File.basename(file)
    basename == '.' || basename == '..' || basename == DeployConfig::PARENT_REF
  end

  def copy_template_file(source_basedir, source_file, target_basedir)
    relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_basedir))
    target_file = File.join(target_basedir, relative_path)
    if File.directory?(source_file)
      FileUtils.mkdir(target_file)
    else
      content = interpolate_template_file(source_file)
      File.open(target_file, 'wb') { |file|
        file.write(content)
      }
    end
  end

  def interpolate_template_file(template_file)
    template = Template.new(IO.read(template_file))
    template.interpolate(@config.template_replacements)
  end

  def write_properties_file(properties, output_file)
    create_parent_dirs(output_file)

    File.open(output_file, 'w') { |f|
      properties.each { |key, value|
        f.puts "#{key}=#{value}"
      }
    }
  end

  def create_parent_dirs(file)
    FileUtils.mkdir_p(File.dirname(file))
  end
end
