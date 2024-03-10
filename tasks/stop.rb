#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb' unless Object.const_defined?('TaskHelper')

# Stop the named Lima VM
class LimaStopTask < TaskHelper
  def task(opts = {})
    stop(opts)
  end

  def stop(opts = {})
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @name = opts.delete(:name)

    { stop: @cli_helper.stop(@name) }
  end
end

LimaStopTask.run if $PROGRAM_NAME == __FILE__
