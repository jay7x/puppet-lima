#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb' unless Object.const_defined?('TaskHelper')

# Start the named Lima VM
class LimaStartTask < TaskHelper
  def task(opts = {})
    start(opts)
  end

  def start(opts)
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @name = opts.delete(:name)
    begin
      { start: @cli_helper.start(@name) }
    rescue Lima::LimaError => e
      raise TaskHelper::Error.new(e.message, 'lima/start-error')
    end
  end
end

LimaStartTask.run if $PROGRAM_NAME == __FILE__
