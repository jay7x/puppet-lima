# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::delete' do
  let(:plan) { 'lima::cluster::delete' }
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
      expect_task('lima::delete').be_called_times(1).with_params('names' => nodes, 'force' => force).always_return(delete: true)
      expect_out_verbose.with_params("Nodes to delete: [#{nodes.join(', ')}]")
    end

    context 'with force unset' do
      it 'deletes all nodes in the cluster' do
        result = run_plan(plan, plan_params)

        expect(result.ok?).to be(true)
        expect(result.value.count).to eq(1)
        expect(result.value[0].value).to eq('delete' => true)
      end
    end

    context 'with force => true' do
      let(:force) { true }
      let(:plan_params) { super().merge('force' => force) }

      it 'deletes all nodes in the cluster' do
        result = run_plan(plan, plan_params)

        expect(result.ok?).to be(true)
        expect(result.value.count).to eq(1)
        expect(result.value[0].value).to eq('delete' => true)
      end
    end
  end
end
