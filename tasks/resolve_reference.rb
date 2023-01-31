#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'shellwords'

# Ugly workaround to make the require_relative working in unit tests too
begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
rescue LoadError
  require_relative '../spec/fixtures/modules/ruby_task_helper/files/task_helper.rb'
end

# Inventory of `lima` VMs
class ResolveReference < TaskHelper
  def initialize
    super

    @ssh_options = {}
    @vm_list = nil
  end

  def task(opts = {})
    targets = resolve_reference(opts)
    { value: targets }
  end

  def set_opts(opts)
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
    matching_vms = get_vms.filter { |vm| vm_matching?(vm) }

    matching_vms.map do |vm|
      name = vm['name']

      {
        'name' => name,
        'ssh_config' => get_vm_ssh_options(name),
      }
    end
  end

  private

  # Get the VMs list
  def get_vms
    return @vm_list if @vm_list

    vms = `#{@limactl} list --json`.split("\n")
    @vm_list = vms.map { |vm| JSON.parse(vm) }
  end

  # Get the VM's ssh config
  def get_vm_ssh_options(vm)
    return @ssh_options[vm] if @ssh_options.key? vm

    lima_output = `#{@limactl} show-ssh -f options #{vm}`
    vm_opts_pairs = Shellwords.shellwords(lima_output).map { |x| x.split('=', 2) }.flatten
    vm_opts = Hash[*vm_opts_pairs]

    # Usually `limactl show-ssh <vm>` will return multiple keys as explained here:
    # https://github.com/lima-vm/lima/blob/master/docs/internal.md#config-directory-lima_home_config
    # Unfortunately Bolt cannot use multiple keys in the transport config (yet?):
    # https://www.puppet.com/docs/bolt/latest/bolt_transports_reference.html#private-key
    # So we'll assume lima is always using its own ssh key..
    lima_home = JSON.parse(`#{@limactl} info`)['limaHome']
    vm_opts['IdentityFile'] = "#{lima_home}/_config/user"

    @ssh_options[vm] = vm_opts
  end
end

ResolveReference.run if $PROGRAM_NAME == __FILE__
