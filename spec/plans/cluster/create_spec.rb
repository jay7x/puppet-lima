# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::create' do
  let(:plan) { subject }
  let(:cluster_name) { 'example' }
  let(:nodes) do
    [
      'example-main',
      'example-node1',
      'example-node2',
      'example-node3',
      'example-node4',
    ]
  end
  let(:clusters) do
    {
      cluster_name => {
        'nodes'    => [
          nodes[0],
          nodes[1],
          {
            'name'   => nodes[2],
            'config' => {
              'node_config_specified' => true,
            },
          },
          {
            'name' => nodes[3],
            'url'  => 'https://example.com/templates/superlinuxdistro.yaml',
          },
          nodes[4],
        ],
        'url'      => 'https://example.com/templates/ubuntu-lts.yaml',
        'config'   => {
          'cluster_config_specified' => true,
        },
      },
    }
  end
  let(:cluster) { clusters[cluster_name] }
  let(:lima_list_res) do
    {
      'list': [
        { 'name': nodes[0], 'status': 'Running' },
        { 'name': nodes[1], 'status': 'Stopped' },
      ]
    }
  end

  it 'fails when wrong name specified' do
    result = run_plan(plan, { 'name' => 'nonexistent', 'clusters' => clusters })

    expect(result.ok?).to be(false)
    expect(result.value.msg).to match(%r{Cluster 'nonexistent' is not defined})
  end

  it 'creates the cluster' do
    expect_plan('lima::clusters').always_return(cluster)
    expect_task('lima::list').be_called_times(1).always_return(lima_list_res)

    # Mock a call to create missing nodes
    [
      cluster['nodes'][2],
      cluster['nodes'][3],
      {
        'name'   => nodes[4],
        'config' => {
          'cluster_config_specified' => true,
        }
      },
    ].each do |node|
      params = {
        'name'     => node['name'],
        'config'   => node['config'],
        'url'      => node['url'],
      }

      expect_task('lima::create').be_called_times(1).with_params(params).always_return(create: true)
    end

    expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")
    expect_out_verbose.with_params("Nodes to create: [#{[ nodes[2], nodes[3], nodes[4] ].join(', ')}]")

    result = run_plan(plan, 'name' => cluster_name, 'clusters' => clusters)

    expect(result.ok?).to be(true)
    expect(result.value.count).to eq(3)
  end
end
