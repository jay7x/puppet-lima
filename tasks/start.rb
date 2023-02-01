#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'tempfile'
require 'shellwords'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Start/create the named Lima VM
class LimaStart < TaskHelper
  def task(opts = {})
    create_or_start(opts)
  end

  def create_or_start(opts = {})
    set_opts(opts)

    vm_definitions = [ @url, @template, @config ].count { |x| x }
    if vm_definitions == 0    # No VM definitions specified -> start the VM
      start
    elsif vm_definitions == 1 # VM config is defined in some way -> create the VM
      create
    else                      # Multiple VM definitions are specified -> error
      raise TaskHelper::Error.new('Only one of url/template/config parameters must be specified', 'lima/create-error')
    end
  end

  def create
    raise TaskHelper::Error.new("Instance '#{@name}' already exists", 'lima/create-error') if vm_exists?(@name)

    if @template
      cfg_url = "template://#{@template}"
    elsif @url
      cfg_url = @url
    elsif @config
      # Write @config to a temporary JSON file and pass it to limactl later
      safe_name = Shellwords.escape(@name)
      tmpfile = Tempfile.new(["lima_#{safe_name}", '.json'])
      tmpfile.write(JSON.dump(@config))
      tmpfile.close
      cfg_url = tmpfile.path
    else
      raise TaskHelper::Error.new('One of url/template/config parameters must be specified', 'lima/create-error')
    end

    stdout_str, stderr_str, status = Open3.capture3(@limactl, 'start', "--name=#{@name}", "--timeout=#{@timeout}", cfg_url)
    tmpfile&.unlink # Delete tmpfile if any

    raise TaskHelper::Error.new(stderr_str, 'lima/start-error') unless status == 0

    { 'stdout': stdout_str }
  end

  def start
    raise TaskHelper::Error.new("No instance named '#{@name}' found", 'lima/start-error') unless vm_exists?(@name)

    stdout_str, stderr_str, status = Open3.capture3(@limactl, 'start', "--timeout=#{@timeout}", @name)
    raise TaskHelper::Error.new(stderr_str, 'lima/start-error') unless status == 0

    { 'stdout': stdout_str }
  end

  def vm_exists?(vm_name)
    stdout_str, = Open3.capture3(@limactl, 'list', '-f', '{{.Name}}', vm_name)
    vms = stdout_str.split("\n")
    vms.include? vm_name
  end

  def set_opts(opts = {})
    @name = opts.delete(:name)
    @limactl = opts.delete(:limactl_path) || 'limactl'
    @timeout = opts.delete(:timeout) || '10m0s'
    @url = opts[:url]
    @template = opts[:template]
    @config = opts[:config]
  end
end

LimaStart.run if $PROGRAM_NAME == __FILE__
