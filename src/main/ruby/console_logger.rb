class ConsoleLogger

  def task_started(server, task)
    header "Executing task #{server}:#{task}"
  end

  def task_succeeded(server, task)
    info "Succeeded in task #{server}:#{task}"
  end

  def task_failed(server, task, exception)
    error "Failed to execute task #{server}:#{task}", exception
  end

  def task_skipped(server, task)
    spacer
    warn "Skipped task #{server}:#{task}"
  end

  def header(message)
    spacer
    info "-" * 72
    info message
    info "-" * 72
  end

  def spacer
    puts
  end

  def info(message)
    puts "[INFO] #{message}"
  end

  def warn(message)
    puts "[WARNING] #{message}"
  end

  def error(message, exception=nil)
    puts "[ERROR] #{message}"
    if exception
      puts "#{exception.class}: #{exception}"
      puts exception.backtrace
    end
  end
end
