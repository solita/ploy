require 'console_logger'
require 'summary'
require 'broadcaster'
require 'cli'

logger = ConsoleLogger.new
summary = Summary.new
task_listener = Broadcaster.new(logger, summary)

CLI.new(ARGV, task_listener, logger).run!

logger.header "SUMMARY"
puts summary.summary_table
exit summary.exit_status
