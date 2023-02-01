# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/list.rb'

describe LimaList do
  let(:task) { described_class.new }
  let(:vms) do
    [
      { 'name': 'default' },
      { 'name': 'test' },
      { 'name': 'example' },
    ]
  end
  let(:lima_stdout) do
    <<~LIMASTR
      {"name":"default"}
      {"name":"test"}
      {"name":"example"}
    LIMASTR
  end
  let(:lima_stderr) { '' }
  let(:lima_code) { 0 }
  let(:lima_response) { [lima_stdout, lima_stderr, lima_code] }
  let(:success_result) { { list: vms.map { |x| x.transform_keys(&:to_s) } } }

  describe '#list' do
    context 'with names specified' do
      let(:opts) { { names: ['test', 'example'] } }

      it 'returns VM list' do
        expect(Open3).to receive(:capture3).with('limactl', 'list', '--json', *opts[:names]).and_return(lima_response)
        result = task.list(opts)
        expect(result).to eq(success_result)
      end
    end

    context 'without names specified' do
      let(:opts) { {} }

      it 'returns VM list' do
        expect(Open3).to receive(:capture3).with('limactl', 'list', '--json').and_return(lima_response)
        result = task.list(opts)
        expect(result).to eq(success_result)
      end
    end
  end
end
