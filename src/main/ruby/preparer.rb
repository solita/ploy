require 'fileutils'
require 'pathname'
require_relative 'template'
require_relative 'maven'

class Preparer

  attr_writer :logging

  def initialize(config, output_dir)
    @config = config
    @output_dir = output_dir
    @logging = true
  end

  def build_all!
    @config.servers.each { |server| build_server!(server) }
  end

  def build_server!(server)
    output_dir = create_output_dir(server)
    build_templates(output_dir, server)
    build_properties_files(output_dir, server)
    build_webapps(output_dir, server)
  end

  private

  def create_output_dir(server)
    output_dir = File.join(@output_dir, server.hostname)
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)
    output_dir
  end

  def log_info(message)
    if @logging
      puts "[INFO] #{message}"
    end
  end


  # Templates

  def build_templates(output_dir, server)
    template_dir = server.template
    if template_dir
      copy_template(template_dir, output_dir)
    end
  end

  def copy_template(template_dir, output_dir)
    raise "Template directory does not exist: #{template_dir}" unless Dir.exist?(template_dir)

    parent_dir = find_parent_template(template_dir)
    if parent_dir
      copy_template(parent_dir, output_dir)
    end

    log_info "Copying template #{template_dir} to #{output_dir}"
    Dir.glob("#{template_dir}/**/*", File::FNM_DOTMATCH).
            reject { |file| special_file?(file) }.
            each { |file| copy_template_file(template_dir, file, output_dir) }
  end

  def find_parent_template(template_dir)
    template_config_file = File.join(template_dir, DeployConfig::TEMPLATE_CONFIG)
    unless File.exist?(template_config_file)
      return nil
    end
    template_config = eval(IO.read(template_config_file))
    parent_path = template_config[:parent]
    if parent_path.nil?
      return nil
    end
    File.absolute_path(parent_path, template_dir) unless parent_path.nil?
  end

  def special_file?(file)
    special_files = ['.', '..', DeployConfig::TEMPLATE_CONFIG, DeployConfig::WEBAPPS_TAG]
    special_files.include?(File.basename(file))
  end

  def copy_template_file(source_basedir, source_file, target_basedir)
    relative_path = Pathname(source_file).relative_path_from(Pathname(source_basedir))
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


  # Properties files

  def build_properties_files(output_dir, server)
    server.properties_files.each { |relative_path, properties|
      output_file = File.join(output_dir, relative_path)
      write_properties_file(properties, output_file)
    }
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


  # Webapps

  def build_webapps(output_dir, server)
    server.webapps.each { |webapp, jar_bundles|
      webapp = MavenArtifact.new(webapp)
      source_file = webapp.path(@config.maven_repository)
      target_file = File.join(output_dir, get_webapps_path(server.template), webapp.simple_name)

      log_info "Copying #{source_file} to #{target_file}"
      FileUtils.cp(source_file, target_file)

      jar_bundles.each { |jar_bundle|
        jar_bundle = MavenArtifact.new(jar_bundle)
        bundle_file = jar_bundle.path(@config.maven_repository)
        embed_into_zip(bundle_file, target_file, 'WEB-INF/lib')
      }
    }
  end

  def get_webapps_path(template_dir)
    marker = Dir.glob("#{template_dir}/**/#{DeployConfig::WEBAPPS_TAG}").first
    if marker
      return Pathname(File.dirname(marker)).relative_path_from(Pathname(template_dir))
    end
    parent_template_dir = find_parent_template(template_dir)
    if parent_template_dir
      return get_webapps_path(parent_template_dir)
    end
    raise "Did not find #{DeployConfig::WEBAPPS_TAG} from #{template_dir}"
  end

  def embed_into_zip(source_file, target_file, subdir)
    log_info "Embedding #{source_file} into #{target_file}"
    Dir.mktmpdir { |unpack_dir|
      Zip.new(source_file).unzip(unpack_dir)

      list_files(unpack_dir).each { |file| log_info "    + #{file}" }
      Zip.new(target_file).add(unpack_dir, subdir)
    }
  end

  def list_files(dir)
    Dir.glob(File.join(dir, "**")).map { |file|
      Pathname.new(file).relative_path_from(Pathname.new(dir))
    }.sort
  end
end
