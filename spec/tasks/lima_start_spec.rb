# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/start.rb'

describe LimaStart do
  let(:task) { described_class.new }

  let(:lima_stdout) { 'Lima message' }
  let(:lima_stderr) { '' }
  let(:lima_code) { 0 }
  let(:lima_response) { [lima_stdout, lima_stderr, lima_code] }
  let(:success_result) { { stdout: lima_stdout } }

  let(:vm_name) { 'test' }
  let(:timeout) { '10m0s' }
  let(:opts) { { name: vm_name, timeout: timeout } }

  describe '#create_or_start' do
    context 'without VM definitions' do
      it 'invokes start once' do
        expect(task).to receive(:start)
        expect(task).not_to receive(:create)

        task.create_or_start(opts)
      end
    end

    shared_examples('create') do
      it 'invokes create once' do
        expect(task).to receive(:create).once
        expect(task).not_to receive(:start)

        task.create_or_start(opts)
      end
    end

    context 'with URL specified' do
      let(:opts) { super().merge(url: 'http://example.com/lima/test.yaml') }

      it_behaves_like 'create'
    end

    context 'with template specified' do
      let(:opts) { super().merge(template: 'superdistro-lts') }

      it_behaves_like 'create'
    end

    context 'with config specified' do
      let(:opts) { super().merge(config: { 'a': 'b' }) }

      it_behaves_like 'create'
    end

    context 'with URL and template specified' do
      let(:opts) { super().merge(template: 'superdistro-lts', config: { 'a': 'b' }) }

      it 'raises the TaskHelper error' do
        expect { task.create_or_start(opts) }.to raise_exception do |e|
          expect(e).to be_a(TaskHelper::Error)
          expect(e.kind).to eq('lima/create-error')
          expect(e.message).to match(%r{Only one of url/template/config parameters must be specified})
        end
      end
    end
  end

  describe '#start' do
    context 'when VM exists' do
      before :each do
        allow(task).to receive(:vm_exists?).with(vm_name).and_return(true)
      end

      it 'invokes `lima start` for the VM' do
        allow(Open3).to receive(:capture3).with('limactl', 'start', "--timeout=#{timeout}", vm_name).and_return(lima_response)

        task.set_opts(opts)
        result = task.start
        expect(result).to eq(success_result)
      end
    end

    context 'when VM does not exists' do
      before :each do
        allow(task).to receive(:vm_exists?).with(vm_name).and_return(false)
      end

      it 'raises the TaskHelper exception' do
        task.set_opts(opts)
        expect { task.start }.to raise_exception do |e|
          expect(e).to be_a(TaskHelper::Error)
          expect(e.kind).to eq('lima/start-error')
          expect(e.message).to match(%r{No instance named '#{vm_name}' found})
        end
      end
    end
  end

  describe '#create' do
    shared_examples('limactl start') do |opts, url|
      it 'invokes `limactl start` with correct parameters' do
        timeout = opts[:timeout] || '10m0s'
        allow(Open3).to receive(:capture3).with('limactl', 'start', "--name=#{opts[:name]}", "--timeout=#{timeout}", url).and_return(lima_response)

        task.set_opts(opts)
        result = task.create
        expect(result).to eq(success_result)
      end
    end

    context 'when VM does not exists' do
      vm_name = 'testx'
      let(:vm_name) { vm_name }

      before :each do
        allow(task).to receive(:vm_exists?).with(vm_name).and_return(false)
      end

      context 'with URL specified' do
        url = 'http://example.com/lima/test.yaml'

        it_behaves_like 'limactl start', { name: vm_name, url: url }, url
      end

      context 'with template specified' do
        template = 'superdisto-lts'

        it_behaves_like 'limactl start', { name: vm_name, template: template }, "template://#{template}"
      end

      context 'with config specified' do
        config = { 'a': 'b' }
        tmpfile = Tempfile.new(["lima_#{vm_name}", '.json'])
        before :each do
          allow(Tempfile).to receive(:new).and_return(tmpfile)
        end
        after :each do
          tmpfile.close
          tmpfile.unlink
        end

        it_behaves_like 'limactl start', { name: vm_name, config: config }, tmpfile.path
      end
    end

    context 'when VM exists' do
      before :each do
        allow(task).to receive(:vm_exists?).with(vm_name).and_return(true)
      end

      it 'raises the TaskHelper exception' do
        task.set_opts(opts)
        expect { task.create }.to raise_exception do |e|
          expect(e).to be_a(TaskHelper::Error)
          expect(e.kind).to eq('lima/create-error')
          expect(e.message).to match(%r{Instance '#{vm_name}' already exists})
        end
      end
    end
  end

  describe '#vm_exists?' do
    before :each do
      task.set_opts(opts)
    end

    context 'when VM exists' do
      it 'returns true' do
        allow(Open3).to receive(:capture3).with('limactl', 'list', '-f', '{{.Name}}', vm_name).and_return("#{vm_name}\n")

        result = task.vm_exists?(vm_name)
        expect(result).to eq(true)
      end
    end

    context 'when VM does not exists' do
      it 'returns false' do
        allow(Open3).to receive(:capture3).with('limactl', 'list', '-f', '{{.Name}}', vm_name).and_return('')

        result = task.vm_exists?(vm_name)
        expect(result).to eq(false)
      end
    end
  end
end
