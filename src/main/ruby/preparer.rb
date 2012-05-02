class Preparer

  def initialize(config, output_dir)
    @config = config
    @output_dir = output_dir
  end

  def build_all!
    @config.servers.each { |hostname, server|
      output_dir = File.join(@output_dir, hostname)
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

    server.properties.each { |relative_path, properties|
      output_file = File.join(output_dir, relative_path)
      write_properties_file(properties, output_file)
    }
  end

  def copy_template(template_dir, output_dir)
    FileUtils.cp_r(File.join(template_dir, '.'), output_dir)
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
