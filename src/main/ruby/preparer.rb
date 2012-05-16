require_relative 'maven'
require_relative 'template'
require_relative 'template_dir'
require_relative 'zip'
require 'fileutils'
require 'pathname'
require 'tmpdir'

class Preparer

  attr_writer :logging

  def initialize(config, logger)
    @config = config
    @logger = logger
    @logging = true
  end

  def build_all!
    @config.servers.each { |server| build_server!(server) }
  end

  def build_server!(server)
    create_output_dir(server)
    build_templates(server)
    build_properties_files(server)
    build_webapps(server)
  end

  private

  def create_output_dir(server)
    dir = server.output_dir
    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
  end


  # Templates

  def build_templates(server)
    template = server.template
    if template
      copy_template(template, server)
    end
  end

  def copy_template(template, server)
    parent = template.parent
    if parent
      copy_template(parent, server)
    end

    output_dir = server.output_dir
    @logger.info "Copying template #{template} to #{output_dir}"
    template.filtered_files.each { |file| copy_filtered(server, file, get_target_file(template.base_dir, file, output_dir)) }
    template.non_filtered_files.each { |file| copy_as_is(file, get_target_file(template.base_dir, file, output_dir)) }
  end

  def get_target_file(source_basedir, source_file, target_basedir)
    relative_path = Pathname(source_file).relative_path_from(Pathname(source_basedir))
    File.join(target_basedir, relative_path)
  end

  def copy_as_is(source_file, target_file)
    create_parent_dirs(target_file)
    FileUtils.cp(source_file, target_file)
  end

  def copy_filtered(server, source_file, target_file)
    create_parent_dirs(target_file)
    content = interpolate_template_file(server, source_file)
    File.open(target_file, 'wb') { |file|
      file.write(content)
    }
  end

  def interpolate_template_file(server, template_file)
    template = Template.new(IO.read(template_file))
    template.interpolate(server.variables)
  end


  # Properties files

  def build_properties_files(server)
    server.properties_files.each { |relative_path, properties|
      output_file = File.join(server.output_dir, relative_path)
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

  def build_webapps(server)
    server.webapps.each { |webapp, jar_bundles|
      webapp = MavenArtifact.new(webapp)
      source_file = webapp.path(@config.maven_repository)
      target_file = File.join(server.output_dir, server.template.get_required(:webapps), webapp.simple_name)

      @logger.info "Copying #{source_file} to #{target_file}"
      create_parent_dirs(target_file)
      FileUtils.cp(source_file, target_file)

      jar_bundles.each { |jar_bundle|
        jar_bundle = MavenArtifact.new(jar_bundle)
        bundle_file = jar_bundle.path(@config.maven_repository)
        embed_into_zip(bundle_file, target_file, 'WEB-INF/lib')
      }
    }
  end

  def embed_into_zip(source_file, target_file, subdir)
    @logger.info "Embedding #{source_file} into #{target_file}"
    Dir.mktmpdir { |unpack_dir|
      Zip.new(source_file).unzip(unpack_dir)

      list_files(unpack_dir).each { |file| @logger.info "    + #{file}" }
      Zip.new(target_file).add(unpack_dir, subdir)
    }
  end

  def list_files(dir)
    Dir.glob(File.join(dir, "**")).map { |file|
      Pathname.new(file).relative_path_from(Pathname.new(dir))
    }.sort
  end
end
