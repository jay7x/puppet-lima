#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb' unless Object.const_defined?('TaskHelper')

# Delete the named Lima VM(s)
class LimaDeleteTask < TaskHelper
  def task(opts = {})
    delete(opts)
  end

  def delete(opts = {})
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @limactl = opts.delete(:limactl_path) || 'limactl'
    @names = opts.delete(:names) || [ opts.delete(:name) ].compact

    { delete: @cli_helper.delete(@names) }
  end
end

LimaDeleteTask.run if $PROGRAM_NAME == __FILE__
