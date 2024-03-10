#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb' unless Object.const_defined?('TaskHelper')

# `limactl info`
class LimaInfoTask < TaskHelper
  def task(opts = {})
    info(opts)
  end

  def info(opts = {})
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)

    begin
      { info: @cli_helper.info }
    rescue Lima::LimaError => e
      raise TaskHelper::Error.new(e.message, 'lima/info-error')
    end
  end
end

LimaInfoTask.run if $PROGRAM_NAME == __FILE__
