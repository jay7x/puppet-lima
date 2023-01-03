# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/resolve_reference.rb'

describe 'LimaInventory' do
  let(:task) { LimaInventory.new }
  let(:vms) do
    [
      { 'name' => 'debian_1', 'status' => 'Running' },
      { 'name' => 'debian_2', 'status' => 'Stopped' },
      { 'name' => 'centos_1', 'status' => 'Running' },
      { 'name' => 'default',  'status' => 'Running' },
    ]
  end
  let(:ssh_config) do
    [
      {
        'name' => 'debian_1',
        'ssh_config' => {
          'Hostname' => '127.0.0.1',
          'Port' => 1234,
          'User' => 'duser',
          'IdentityFile' => '/home/duser/.lima/_config/user',
        },
      },
      {
        'name' => 'centos_1',
        'ssh_config' => {
          'Hostname' => '127.0.0.2',
          'Port' => 1235,
          'User' => 'cuser',
          'IdentityFile' => '/home/cuser/.lima/_config/user',
        },
      },
      {
        'name' => 'default',
        'ssh_config' => {
          'Hostname' => '127.0.0.3',
          'Port' => 1236,
          'User' => 'test',
          'IdentityFile' => '/home/test/.lima/_config/user',
        },
      },
    ]
  end
  let(:targets) do
    [
      {
        'name' => 'debian_1',
        'uri' => 'ssh://127.0.0.1:1234',
        'config' => {
          'ssh' => {
            'host-key-check' => false,
            'private-key' => '/home/duser/.lima/_config/user',
            'user' => 'duser',
          },
        },
      },
      {
        'name' => 'centos_1',
        'uri' => 'ssh://127.0.0.2:1235',
        'config' => {
          'ssh' => {
            'host-key-check' => false,
            'private-key' => '/home/cuser/.lima/_config/user',
            'user' => 'cuser',
          },
        },
      },
      {
        'name' => 'default',
        'uri' => 'ssh://127.0.0.3:1236',
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

  describe '#vm_matching?' do
    shared_examples('VM matcher') do |opts, want|
      count = want.reduce(0) { |memo, x| x ? memo + 1 : memo }
      it "returns true for #{count} VMs" do
        task.set_opts(opts)

        vms.each_with_index { |vm, idx| expect(task.vm_matching?(vm)).to be(want[idx]) }
      end
    end

    context 'with empty opts' do
      it_behaves_like 'VM matcher', {}, [true, false, true, true]
    end

    context 'with only_matching_names' do
      it_behaves_like 'VM matcher', { only_matching_names: '^de.*' }, [true, false, false, true]
    end

    context 'with except_matching_names' do
      it_behaves_like 'VM matcher', { except_matching_names: '_1$' }, [false, false, false, true]
    end

    context 'with only_matching_names and except_matching_names' do
      it_behaves_like 'VM matcher',
        { only_matching_names: '^de.*', except_matching_names: '_1$' },
        [false, false, false, true]
    end
  end

  describe '#get_ssh_config' do
    it 'returns ssh config' do
      ssh_options = {
        'Hostname' => '127.0.0.1',
        'Port' => 1234,
        'User' => 'test_user',
        'IdentityFile' => '/home/test_user/.lima/_config/user',
      }
      want = [
        { 'name' => 'debian_1', 'ssh_config' => ssh_options },
        { 'name' => 'centos_1', 'ssh_config' => ssh_options },
        { 'name' => 'default',  'ssh_config' => ssh_options },
      ]

      allow(task).to receive(:get_vms).and_return(vms)
      allow(task).to receive(:get_vm_ssh_options).and_return(ssh_options)
      nodes = task.get_ssh_config

      expect(nodes).to eq(want)
    end
  end

  describe '#resolve_reference' do
    it 'returns all running targets' do
      opts = {}
      allow(task).to receive(:get_ssh_config).and_return(ssh_config)
      res = task.resolve_reference(opts)

      expect(res).to eq(targets)
    end
  end

  describe '#task' do
    it 'runs the task' do
      opts = {}
      allow(task).to receive(:resolve_reference).and_return(targets)
      result = task.task(opts)

      expect(result).to have_key(:value)
      expect(result[:value]).to eq(targets)
    end
  end
end
