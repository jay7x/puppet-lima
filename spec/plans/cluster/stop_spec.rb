# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::stop' do
  let(:plan) { subject }
  let(:cluster_name) { 'example' }
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
      cluster_name => {
        'nodes'    => [
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

  it 'fails when wrong name specified' do
    result = run_plan(plan, { 'name' => 'nonexistent', 'clusters' => clusters })

    expect(result.ok?).to be(false)
    expect(result.value.msg).to match(%r{Cluster 'nonexistent' is not defined})
  end

  it 'stops all non-running nodes in the cluster' do
    expect_plan('lima::clusters').always_return(cluster)
    expect_task('lima::list').be_called_times(1).always_return(lima_list_res)

    nodes_to_stop = [
      nodes[0],
      nodes[2],
    ]
    nodes_to_stop.each do |node|
      expect_task('lima::stop').be_called_times(1).with_params({ 'name' => node }).always_return({})
    end

    expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")
    expect_out_verbose.with_params("Nodes to stop: [#{nodes_to_stop.join(', ')}]")

    result = run_plan(plan, { 'name' => cluster_name, 'clusters' => clusters })

    expect(result.ok?).to be(true)
    expect(result.value.count).to eq(nodes_to_stop.length)
  end
end
