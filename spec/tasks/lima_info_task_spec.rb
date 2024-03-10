# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/modules/ruby_task_helper/files/task_helper.rb'
require_relative '../../tasks/info.rb'

describe LimaInfoTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: lima_helper } }
  let(:info) { { 'version' => '1.2.3' } }
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return(info)
    helper
  end

  describe '#task' do
    it 'returns `limactl info` output' do
      result = task.task(opts)
      expect(lima_helper).to have_received(:info).once
      expect(result).to eq({ info: info })
    end
  end
end
