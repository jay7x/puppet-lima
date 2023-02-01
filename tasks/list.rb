#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# List Lima VMs
class LimaList < TaskHelper
  def task(opts = {})
    list(opts)
  end

  def list(opts = {})
    @names = opts.delete(:names) || []
    @limactl = opts.delete(:limactl_path) || 'limactl'

    args = [@limactl, 'list', '--json'] + @names

    stdout_str, stderr_str, status = Open3.capture3(*args)
    raise TaskHelper::Error.new(stderr_str, 'lima/list-error') unless status == 0

    { list: stdout_str.split("\n").map { |vm| JSON.parse(vm) } }
  end
end

LimaList.run if $PROGRAM_NAME == __FILE__
