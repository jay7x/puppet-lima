# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/modules/ruby_task_helper/files/task_helper.rb'
require_relative '../../tasks/start.rb'

describe LimaStartTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: lima_helper } }
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return({ 'version' => '1.2.3' })
    helper
  end

  describe '#task' do
    context 'with name specified' do
      let(:opts) { super().merge({ name: 'test' }) }

      it 'starts the VM' do
        allow(lima_helper).to receive(:start).with(opts[:name]).and_return(true)

        result = task.task(opts)
        expect(lima_helper).to have_received(:start).once
        expect(result).to eq({ start: true })
      end
    end
  end
end
