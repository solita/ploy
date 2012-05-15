class TaskExecutor

  def initialize(config, listener)
    @config = config
    @listener = listener
  end

  def execute(task_ids)
    failed_servers = []

    task_ids.each { |task_id|
      @config.servers.each { |server|
        task = server.tasks[task_id]
        if failed_servers.include? server
          @listener.task_skipped(server.hostname, task_id)
        else
          begin
            unless task.nil?
              @listener.task_started(server.hostname, task_id)
              task.call(server)
              @listener.task_succeeded(server.hostname, task_id)
            end
          rescue
            failed_servers << server
            @listener.task_failed(server.hostname, task_id, $!)
          end
        end
      }
    }
  end
end
