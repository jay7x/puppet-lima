# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::stop' do
  let(:plan) { 'lima::cluster::stop' }
  let(:nodes) do
    [
      'example-main',
      'example-node1',
      'example-node2',
      'example-node3',
    ]
  end
  let(:clusters) do
    {
      'example' => {
        'nodes' => [
          nodes[0],
          nodes[1],
          {
            'name' => nodes[2],
          },
          {
            'name' => nodes[3],
          },
        ],
      },
    }
  end
  let(:cluster_name) { 'example' }
  let(:cluster) { clusters[cluster_name] }
  let(:lima_list_res) do
    {
      'list': [
        { 'name': nodes[0], 'status': 'Running' },
        { 'name': nodes[1], 'status': 'Stopped' },
        { 'name': nodes[2], 'status': 'Running' },
      ]
    }
  end
  let(:nodes_to_stop) { [nodes[0], nodes[2]] }
  let(:plan_params) { { 'name' => cluster_name, 'clusters' => clusters } }
  let(:force) { false }

  context 'with non-existent cluster' do
    let(:cluster_name) { 'nonexistent' }

    it 'fails' do
      result = run_plan(plan, plan_params)

      expect(result.ok?).to be(false)
      expect(result.value.msg).to match(%r{Cluster 'nonexistent' is not defined})
    end
  end

  context 'with existing cluster' do
    before :each do
      expect_plan('lima::clusters').always_return(cluster)
      expect_task('lima::list').be_called_times(1).always_return(lima_list_res)
      nodes_to_stop.each do |node|
        expect_task('lima::stop').be_called_times(1).with_params('name' => node, 'force' => force).always_return(stop: true)
      end
      expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")
      expect_out_verbose.with_params("Nodes to stop: [#{nodes_to_stop.join(', ')}]")
    end

    context 'with force unset' do
      it 'stops all non-running nodes in the cluster' do
        result = run_plan(plan, plan_params)

        expect(result.ok?).to be(true)
        expect(result.value.count).to eq(nodes_to_stop.length)
        result.value.each do |r|
          expect(r.first.value).to eq('stop' => true)
        end
      end
    end

    context 'with force => true' do
      let(:force) { true }
      let(:plan_params) { super().merge('force' => force) }
      let(:nodes_to_stop) { [nodes[0], nodes[1], nodes[2]] }

      it 'stops all non-running nodes in the cluster' do
        result = run_plan(plan, plan_params)

        expect(result.ok?).to be(true)
        expect(result.value.count).to eq(nodes_to_stop.length)
        result.value.each do |r|
          expect(r.first.value).to eq('stop' => true)
        end
      end
    end
  end
end
