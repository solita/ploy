class Summary

  def initialize()
    @has_failures = false
    @servers = []
    @tasks = []
    @results = {}
  end

  def task_started(server, task)
    record(server, task, :STARTED)
  end


  def task_succeeded(server, task)
    record(server, task, :OK)
  end

  def task_failed(server, task, exception)
    record(server, task, :FAILED)
    @has_failures = true
  end

  def task_skipped(server, task)
    record(server, task, :SKIPPED)
  end

  def record(server, task, status)
    @servers << server unless @servers.include?(server)
    @tasks << task unless @tasks.include?(task)
    @results[[server, task]] = status
  end

  def get_result(server, task)
    result = @results[[server, task]]
    if result
      result.to_s
    else
      "-"
    end
  end

  def exit_status
    failed = @has_failures || @tasks.empty?
    failed ? 1 : 0
  end

  def summary_table
    table = ""
    table << @tasks.join(' ') + "\n"
    @servers.each do |server|
      table << server + " "
      @tasks.each do |task|
        table << get_result(server, task) + " "
      end
      table << "\n"
    end
    table
  end
end
