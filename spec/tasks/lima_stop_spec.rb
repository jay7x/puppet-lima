# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/stop.rb'

describe LimaStop do
  let(:task) { described_class.new }
  let(:lima_stdout) { 'Lima message' }
  let(:lima_stderr) { '' }
  let(:lima_code) { 0 }
  let(:lima_response) { [lima_stdout, lima_stderr, lima_code] }
  let(:success_result) { { stdout: lima_stdout } }

  describe '#stop' do
    context 'with name specified' do
      vm_name = 'test'
      let(:opts) { { name: vm_name } }

      it "invokes `lima stop #{vm_name}`" do
        expect(Open3).to receive(:capture3).with('limactl', 'stop', vm_name).and_return(lima_response)
        result = task.stop(opts)
        expect(result).to eq(success_result)
      end
    end
  end
end
