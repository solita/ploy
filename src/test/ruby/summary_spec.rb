require_relative '../../main/ruby/summary'
require_relative 'test_helpers'

describe Summary do

  before :each do
    @summary = Summary.new
  end

  describe "exit status" do

    it "succeeds if all tasks succeed" do
      @summary.task_started('server1', :task1)
      @summary.task_succeeded('server1', :task1)

      @summary.exit_status.should == 0
    end

    it "fails if one or more tasks fail" do
      @summary.task_started('server1', :task1)
      @summary.task_failed('server1', :task1, Exception.new('failure'))
      @summary.task_started('server2', :task1)
      @summary.task_succeeded('server2', :task1)

      @summary.exit_status.should_not == 0
    end

    it "fails if no tasks were executed" do
      @summary.exit_status.should_not == 0
    end
  end

  describe "summary table" do

    it "all tasks are in columns" do
      @summary.task_started('any server', :task1)
      @summary.task_succeeded('any server', :task1)
      @summary.task_started('any server', :task2)
      @summary.task_succeeded('any server', :task2)

      rows = @summary.summary_table.lines.to_a
      rows[0].should =~ /task1.+task2/
    end

    it "each task is listed only once" do
      @summary.task_started('server1', :task1)
      @summary.task_succeeded('server1', :task1)
      @summary.task_started('server2', :task1)
      @summary.task_succeeded('server2', :task1)

      @summary.summary_table.should_not =~ /task1.*task1/m
    end

    it "all servers are in rows" do
      @summary.task_started('server1', :any_task)
      @summary.task_succeeded('server1', :any_task)
      @summary.task_started('server2', :any_task)
      @summary.task_succeeded('server2', :any_task)

      rows = @summary.summary_table.lines.to_a
      rows[1].should =~ /server1/
      rows[2].should =~ /server2/
    end

    it "each server is listed only once" do
      @summary.task_started('server1', :task1)
      @summary.task_succeeded('server1', :task1)
      @summary.task_started('server1', :task2)
      @summary.task_succeeded('server1', :task2)

      @summary.summary_table.should_not =~ /server1.*server1/m
    end

    it "shows succeeded tasks" do
      @summary.task_started('server1', :task1)
      @summary.task_succeeded('server1', :task1)

      @summary.summary_table.should =~ /OK/
    end

    it "shows failed tasks" do
      @summary.task_started('server1', :task1)
      @summary.task_failed('server1', :task1, Exception.new('failure'))

      @summary.summary_table.should =~ /FAILED/
    end

    it "shows skipped tasks" do
      @summary.task_skipped('server1', :task1)

      @summary.summary_table.should =~ /SKIPPED/
    end

    it "shows missing tasks" do
      @summary.task_started('server1', :task1)
      @summary.task_succeeded('server1', :task1)
      @summary.task_started('server2', :task2)
      @summary.task_succeeded('server2', :task2)


      rows = @summary.summary_table.lines.to_a
      rows[0].should =~ /task1.+task2/
      rows[1].should =~ /server1.+OK.+-/
      rows[2].should =~ /server2.+-.+OK/
    end

    # TODO: alignment
  end
end
