#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Stop the named Lima VM
class LimaStop < TaskHelper
  def task(opts = {})
    stop(opts)
  end

  def stop(opts = {})
    @name = opts.delete(:name)
    @limactl = opts.delete(:limactl_path) || 'limactl'

    stdout_str, stderr_str, status = Open3.capture3(@limactl, 'stop', @name)
    raise TaskHelper::Error.new(stderr_str, 'lima/stop-error') unless status == 0

    { 'stdout': stdout_str }
  end
end

LimaStop.run if $PROGRAM_NAME == __FILE__
