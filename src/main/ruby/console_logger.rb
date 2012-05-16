class ConsoleLogger

  def task_started(hostname, task)
    header "Executing task #{task}/#{hostname}"
  end

  def task_succeeded(hostname, task)
    info "Succeeded in task #{task}/#{hostname}"
  end

  def task_failed(hostname, task, exception)
    error "Failed to execute task #{task}/#{hostname}", exception
  end

  def task_skipped(hostname, task)
    spacer
    warn "Skipped task #{task}/#{hostname}"
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
