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
    template = server.template
    if template
      FileUtils.cp_r(File.join(template, '.'), output_dir)
    end
  end
end
