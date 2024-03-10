# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/modules/ruby_task_helper/files/task_helper.rb'
require_relative '../../tasks/resolve_reference.rb'

describe ResolveReferenceTask do
  let(:task) { described_class.new }
  let(:vms) do
    [
      { 'name' => 'debian_1', 'status' => 'Running', 'IdentityFile' => '/home/test/.lima/_config/user' },
      { 'name' => 'debian_2', 'status' => 'Stopped' },
      { 'name' => 'debian_3', 'status' => 'Running', 'IdentityFile' => '/home/test/.lima/_config/user' },
      { 'name' => 'default',  'status' => 'Running', 'IdentityFile' => '/home/test/.lima/_config/user' },
    ]
  end
  let(:ssh_config) do
    {
      'debian_1' => {
        'Hostname' => '127.0.0.1',
        'Port' => 1234,
        'User' => 'test',
        'IdentityFile' => '/home/test/.ssh/debian',
      },
      'debian_3' => {
        'Hostname' => '127.0.0.1',
        'Port' => 1235,
        'User' => 'test',
        'IdentityFile' => '/home/test/.ssh/centos',
      },
      'default' => {
        'Hostname' => '127.0.0.1',
        'Port' => 1236,
        'User' => 'test',
        'IdentityFile' => '/home/test/.ssh/default',
      },
    }
  end
  let(:targets) do
    [
      {
        'name' => 'debian_1',
        'uri' => 'ssh://127.0.0.1:1234',
        'config' => {
          'ssh' => {
            'host-key-check' => false,
            'private-key' => '/home/test/.lima/_config/user',
            'user' => 'test',
          },
        },
      },
      {
        'name' => 'debian_3',
        'uri' => 'ssh://127.0.0.1:1235',
        'config' => {
          'ssh' => {
            'host-key-check' => false,
            'private-key' => '/home/test/.lima/_config/user',
            'user' => 'test',
          },
        },
      },
      {
        'name' => 'default',
        'uri' => 'ssh://127.0.0.1:1236',
        'config' => {
          'ssh' => {
            'host-key-check' => false,
            'private-key' => '/home/test/.lima/_config/user',
            'user' => 'test',
          },
        },
      },
    ]
  end
  let(:opts) { { cli_helper: lima_helper } }
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return({ 'version' => '1.2.3' })
    helper
  end

  describe '#task' do
    before :each do
      allow(lima_helper).to receive(:list).with(no_args).and_return(vms)
    end

    context 'with default options' do
      it 'returns all running targets' do
        vms.each do |vm|
          name = vm['name']
          allow(lima_helper).to receive(:ssh_info).with(name).and_return(ssh_config[name])
        end

        res = task.task(opts)

        expect(res).to eq(value: targets)
      end
    end

    context 'with only_matching_names' do
      let(:opts) { super().merge(only_matching_names: '^debian.*') }

      it 'returns matching targets' do
        [vms[0], vms[2]].each do |vm|
          name = vm['name']
          allow(lima_helper).to receive(:ssh_info).with(name).and_return(ssh_config[name])
        end

        res = task.task(opts)

        expect(res).to eq(value: [targets[0], targets[1]])
      end
    end

    context 'with except_matching_names' do
      let(:opts) { super().merge(except_matching_names: '_[12]$') }

      it 'returns matching targets' do
        [vms[2], vms[3]].each do |vm|
          name = vm['name']
          allow(lima_helper).to receive(:ssh_info).with(name).and_return(ssh_config[name])
        end

        res = task.task(opts)

        expect(res).to eq(value: [targets[1], targets[2]])
      end
    end

    context 'with only_matching_names and except_matching_names' do
      let(:opts) { super().merge(only_matching_names: '^debian*', except_matching_names: '_[12]$') }

      it 'returns matching targets' do
        [vms[2]].each do |vm|
          name = vm['name']
          allow(lima_helper).to receive(:ssh_info).with(name).and_return(ssh_config[name])
        end

        res = task.task(opts)

        expect(res).to eq(value: [targets[1]])
      end
    end
  end
end
