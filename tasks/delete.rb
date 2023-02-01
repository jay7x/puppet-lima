#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Delete the named Lima VM
class LimaDelete < TaskHelper
  def task(opts = {})
    delete(opts)
  end

  def delete(opts = {})
    @name = opts.delete(:name)
    @limactl = opts.delete(:limactl_path) || 'limactl'

    stdout_str, stderr_str, status = Open3.capture3(@limactl, 'delete', @name)
    raise TaskHelper::Error.new(stderr_str, 'lima/delete-error') unless status == 0

    { 'stdout': stdout_str }
  end
end

LimaDelete.run if $PROGRAM_NAME == __FILE__
