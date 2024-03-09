#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/cli_helper.rb'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Create the named Lima VM
class LimaCreateTask < TaskHelper
  def task(opts = {})
    create(opts)
  end

  def create(opts)
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @name = opts.delete(:name)
    @url = opts.delete(:url)
    @config = opts.delete(:config)
    begin
      { create: @cli_helper.create(@name, { url: @url, config: @config }) }
    rescue Lima::LimaError => e
      raise TaskHelper::Error.new(e.message, 'lima/create-error')
    end
  end
end

LimaCreateTask.run if $PROGRAM_NAME == __FILE__
