#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cli_helper'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Inventory of `lima` VMs
class ResolveReferenceTask < TaskHelper
  def task(opts = {})
    targets = resolve_reference(opts)
    { value: targets }
  end

  def set_opts(opts)
    @cli_helper ||= opts.delete(:cli_helper) || Lima::CliHelper.new(opts)
    @limactl = opts.delete(:limactl_path) || 'limactl'
    @only_names = opts[:only_matching_names].nil? ? nil : Regexp.new(opts[:only_matching_names])
    @except_names = opts[:except_matching_names].nil? ? nil : Regexp.new(opts[:except_matching_names])
  end

  def resolve_reference(opts)
    set_opts(opts)

    get_ssh_config.map do |vm|
      cfg = vm['ssh_config']
      {
        'uri'    => "ssh://#{cfg['Hostname']}:#{cfg['Port']}",
        'name'   => vm['name'],
        'config' => {
          'ssh' => {
            'user'           => cfg['User'],
            'private-key'    => cfg['IdentityFile'],
            'host-key-check' => false,
          },
        },
      }
    end
  end

  def vm_matching?(vm)
    name = vm['name']
    vm['status'] == 'Running' &&
      (@only_names.nil? ? true : @only_names.match?(name)) &&
      (@except_names.nil? ? true : !@except_names.match?(name))
  end

  def get_ssh_config
    matching_vms = @cli_helper.list.filter { |vm| vm_matching?(vm) }

    matching_vms.map do |vm|
      name = vm['name']
      ssh_options = @cli_helper.ssh_info(name)
      # Bolt cannot use multiple identities so far. Assume lima always uses it's own key.
      ssh_options['IdentityFile'] = vm['IdentityFile']

      {
        'name' => name,
        'ssh_config' => ssh_options,
      }
    end
  end
end

ResolveReferenceTask.run if $PROGRAM_NAME == __FILE__
