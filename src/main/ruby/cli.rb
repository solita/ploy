require_relative 'deploy_config'
require_relative 'preparer'

class CLI

  def initialize(args)
    @args = args
  end

  def run!()
    if @args[0] == 'prepare'
      config_file = @args[1]
      output_dir = @args[2]

      config = DeployConfig.new
      eval(IO.read(config_file), get_binding_for_config_file(config), config_file)

      preparer = Preparer.new(config, output_dir)
      preparer.build_all!
    end
  end

  private

  def get_binding_for_config_file(config)
    binding
  end
end
