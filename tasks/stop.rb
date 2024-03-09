#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cli_helper'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

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
