# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/modules/ruby_task_helper/files/task_helper.rb'
require_relative '../../tasks/stop.rb'

describe LimaStopTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: lima_helper } }
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return('version' => '1.2.3')
    helper
  end

  describe '#task' do
    context 'with name specified' do
      let(:opts) { super().merge(name: 'test') }

      context 'with force unset' do
        it 'stops the VM' do
          allow(lima_helper).to receive(:stop).with(opts[:name], false).and_return(true)

          result = task.task(opts)
          expect(result).to eq(stop: true)
        end
      end

      context 'with force=true' do
        let(:opts) { super().merge(force: true) }

        it 'stops the VM in force mode' do
          allow(lima_helper).to receive(:stop).with(opts[:name], opts[:force]).and_return(true)

          result = task.task(opts)
          expect(result).to eq(stop: true)
        end
      end
    end
  end
end
