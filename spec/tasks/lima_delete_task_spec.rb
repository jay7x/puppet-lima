# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/delete.rb'

describe LimaDeleteTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: lima_helper } }
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return({ 'version' => '1.2.3' })
    helper
  end

  describe '#task' do
    context 'with name specified (deprecated)' do
      let(:opts) { super().merge({ name: 'test' }) }

      it 'deletes the VM' do
        allow(lima_helper).to receive(:delete).with([opts[:name]]).and_return(true)

        result = task.task(opts)
        expect(result).to eq({ delete: true })
      end
    end

    context 'with multiple names specified' do
      let(:opts) { super().merge({ names: ['test', 'examples'] }) }

      it 'deletes the VMs' do
        allow(lima_helper).to receive(:delete).with(opts[:names]).and_return(true)

        result = task.task(opts)
        expect(result).to eq({ delete: true })
      end
    end
  end
end
