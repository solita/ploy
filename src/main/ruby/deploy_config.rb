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

  def server(*hostnames)
    server_config = ServerConfig.new
    yield server_config
  end

end

class ServerConfig

  def use_template(source_path)
  end

  def use_properties(target_path, properties)
  end

  def install_war(war, manuscripts = [])
  end
end