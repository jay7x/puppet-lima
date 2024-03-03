# frozen_string_literal: true

require 'spec_helper'
require_relative '../../tasks/list.rb'

describe LimaListTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: lima_helper } }
  let(:vms) do
    [
      { 'name': 'default' },
      { 'name': 'test' },
      { 'name': 'example' },
    ]
  end
  let(:lima_helper) do
    helper = instance_double(Lima::CliHelper)
    allow(helper).to receive(:info).and_return({ 'version' => '1.2.3' })
    helper
  end

  describe '#task' do
    context 'with names specified' do
      let(:opts) { super().merge({ names: ['test', 'example'] }) }
      let(:res) { opts[:names].map { |vm| { 'name' => vm, 'status' => 'Running' } } }

      it 'returns VM list' do
        allow(lima_helper).to receive(:list).with(opts[:names]).and_return(res)

        result = task.task(opts)
        expect(lima_helper).to have_received(:list).once
        expect(result).to eq({ list: res })
      end
    end

    context 'without names specified' do
      let(:res) { vms.map { |vm| { 'name' => vm[:name], 'status' => 'Running' } } }

      it 'returns VM list' do
        allow(lima_helper).to receive(:list).with([]).and_return(res)

        result = task.task(opts)
        expect(lima_helper).to have_received(:list).once
        expect(result).to eq({ list: res })
      end
    end
  end
end
