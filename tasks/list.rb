#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb' unless Object.const_defined?('TaskHelper')

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
