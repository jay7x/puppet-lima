#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cli_helper'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

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
