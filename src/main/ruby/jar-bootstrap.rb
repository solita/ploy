require 'console_logger'
require 'cli'

CLI.new(ARGV, ConsoleLogger.new).run!
