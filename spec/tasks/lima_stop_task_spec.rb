# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/stop.rb'

describe LimaStopTask do
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

      it 'stops the VM' do
        allow(lima_helper).to receive(:stop).with(opts[:name]).and_return(true)

        result = task.task(opts)
        expect(result).to eq({ stop: true })
      end
    end
  end
end
