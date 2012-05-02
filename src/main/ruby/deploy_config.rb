class DeployConfig

  attr_writer :scheduler_db_url,
              :scheduler_db_user_username,
              :scheduler_db_user_password,
              :scheduler_db_admin_username,
              :scheduler_db_admin_password,
              :runner_db_url,
              :runner_db_user_username,
              :runner_db_user_password,
              :runner_db_admin_username,
              :runner_db_admin_password

  attr_accessor :servers

  def initialize()
    @servers = {}
  end

  def server(*hostnames)
    server_config = ServerConfig.new
    yield server_config

    hostnames.each { |hostname|
      @servers[hostname] = server_config
    }
  end
end

class ServerConfig

  attr_accessor :template

  def use_template(source_path)
    @template = source_path
  end

  def use_properties(target_path, properties)
  end

  def install_war(war, manuscripts = [])
  end
end
