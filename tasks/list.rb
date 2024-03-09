#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# List Lima VMs
class LimaListTask < TaskHelper
  def task(opts = {})
    list(opts)
  end

  def list(opts = {})
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @names = opts.delete(:names) || []
    begin
      { list: @cli_helper.list(@names) }
    rescue Lima::LimaError => e
      raise TaskHelper::Error.new(e.message, 'lima/list-error')
    end
  end
end

LimaListTask.run if $PROGRAM_NAME == __FILE__
