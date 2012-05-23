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

  def failed_tasks?
    @has_failures
  end

  def no_tasks?
    @tasks.empty?
  end

  def exit_status
    failed = failed_tasks?() || no_tasks?()
    failed ? 1 : 0
  end

  def summary_table
    rows = []
    rows << [''] + @tasks.map { |task| task.to_s }
    @servers.each do |server|
      rows << [server] + @tasks.map { |task| get_result(server, task) }
    end

    columns = rows.transpose
    column_widths = columns.map { |column| column.map { |cell| cell.length }.max }
    spacing = '  '

    table = ""
    rows.each do |row|
      row.each_index do |i|
        table << row[i].ljust(column_widths[i], ' ') + spacing
      end
      table << "\n"
    end

    if failed_tasks?
      table << "There were some failed tasks.\n"
    end
    if no_tasks?
      table << "No tasks were executed. Maybe the task name was misspelt?\n"
    end
    table
  end
end
