require_relative '../../main/ruby/task_executor'
require_relative 'test_helpers'
require 'tmpdir'

describe TaskExecutor do

  before(:each) do
    @sandbox = Dir.mktmpdir()
    @config = DeployConfig.new
    @listener = double("null-listener").as_null_object
    @spy = []
  end

  after(:each) do
    FileUtils.rm_rf(@sandbox)
  end

  def execute(*tasks)
    executor = TaskExecutor.new(@config, @listener)
    executor.execute(tasks)
  end


  # executing

  it "servers can have tasks which can be executed by name" do
    task1 = proc do
      @spy << "run"
    end
    @config.server 'server1' do |server|
      server.tasks[:task1] = task1
    end

    execute :task1

    @spy.should == ["run"]
  end

  it "if a server doesn't have the task, it's silently ignored" do
    @config.server 'server1' do |server|
    end

    execute :no_such_task
  end

  it "multiple tasks are executed in the specified order" do
    @config.server 'server1' do |server|
      server.tasks[:task2] = proc do
        @spy << "task2"
      end
      server.tasks[:task1] = proc do
        @spy << "task1"
      end
      server.tasks[:task3] = proc do
        @spy << "task3"
      end
    end

    execute :task1, :task2, :task3

    @spy.should == ["task1", "task2", "task3"]
  end

  it "multiple servers are processed in declaration order" do
    @config.server 'server1' do |server|
      server.tasks[:task1] = proc do
        @spy << 'server1'
      end
    end
    @config.server 'server2', 'server3' do |server|
      server.tasks[:task1] = proc do
        @spy << server.hostname
      end
    end

    execute :task1

    @spy.should == ["server1", "server2", "server3"]
  end

  it "a task is executed for all servers before executing the next task" do
    @config.server 'server1', 'server2' do |server|
      server.tasks[:task1] = proc do
        @spy << "task1 "+server.hostname
      end
      server.tasks[:task2] = proc do
        @spy << "task2 "+server.hostname
      end
    end

    execute :task1, :task2

    @spy.should == ["task1 server1", "task1 server2", "task2 server1", "task2 server2"]
  end


  # configuration & reuse

  it "reusable tasks can take the server as a parameter" do
    task1 = proc do |server|
      @spy << server.hostname
    end
    @config.server 'server1', 'server2', 'server3' do |server|
      server.tasks[:task1] = task1
    end

    execute :task1

    @spy.should == ["server1", "server2", "server3"]
  end

  it "default tasks are automatically added to all servers" do
    @config.default_tasks = {:task1 => proc { @spy << "default task1" }}

    @config.server 'server1' do
    end

    execute :task1

    @spy.should == ["default task1"]
  end

  it "default tasks can be customized per server" do
    @config.default_tasks = {:task1 => proc { @spy << "default task1" }}

    @config.server 'server1' do |server|
      default_task1 = server.tasks[:task1]
      server.tasks[:task1] = proc do |s|
        @spy << "before"
        default_task1.call(s)
        @spy << "after"
      end
    end

    execute :task1

    @spy.should == ["before", "default task1", "after"]
  end


  # failure handling & reporting

  it "when a task fails, that server's subsequent tasks are skipped" do
    @config.server 'server1' do |server|
      server.tasks[:task1] = proc do
        @spy << "task1"
        raise "dummy exception"
      end
      server.tasks[:task2] = proc do
        @spy << "task2"
      end
    end

    execute :task1, :task2

    @spy.should == ["task1"]
  end

  it "when a task fails, unrelated servers' tasks are executed normally" do
    @config.server 'server1', 'server2' do |server|
      server.tasks[:task1] = proc do
        @spy << server.hostname
        raise "dummy exception" if server.hostname == 'server1'
      end
    end

    execute :task1

    @spy.should == ["server1", "server2"]
  end

  it "the execution status of tasks are reported to a listener" do
    @config.server 'server1' do |server|
      server.tasks[:task1] = proc do
      end
      server.tasks[:task2] = proc do
        raise "dummy exception"
      end
      server.tasks[:task3] = proc do
      end
    end

    @listener = double("listener")
    @listener.should_receive(:task_started).with('server1', :task1)
    @listener.should_receive(:task_succeeded).with('server1', :task1)
    @listener.should_receive(:task_started).with('server1', :task2)
    @listener.should_receive(:task_failed).with('server1', :task2, kind_of(RuntimeError))
    @listener.should_receive(:task_skipped).with('server1', :task3)

    execute :no_such_task, :task1, :task2, :task3
  end
end
