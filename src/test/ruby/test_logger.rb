class TestLogger

  def info(message)
  end

  def task_started(hostname, task)
  end

  def task_succeeded(hostname, task)
  end

  def task_failed(hostname, task, exception)
    puts exception.inspect
    puts exception.backtrace
  end

  def task_skipped(hostname, task)
  end
end