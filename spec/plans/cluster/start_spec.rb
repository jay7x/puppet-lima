# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::start' do
  let(:plan) { subject }
  let(:cluster_name) { 'example' }
  let(:nodes) do
    [
      'example-main',
      'example-node1',
      'example-node2',
      'example-node3',
      'example-node4',
      'example-node5',
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
            'name'     => nodes[3],
            'template' => 'superlinuxdistro',
          },
          {
            'name' => nodes[4],
            'url'  => 'https://example.com/templates/superlinuxdistro.yaml',
          },
          nodes[5],
        ],
        'template' => 'ubuntu-lts',
        'url'      => 'https://example.com/templates/ubuntu-lts.yaml',
        'config'   => {
          'cluster_config_specified' => true,
        },
      },
    }
  end
  let(:cluster) { clusters[cluster_name] }
  let(:facts) { { 'processors': { 'count': 1 } } }
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

  it 'creates and runs the cluster' do
    allow_task('facts').always_return(facts)

    expect_plan('lima::clusters').always_return(cluster)
    expect_task('lima::list').be_called_times(1).always_return(lima_list_res)

    # Mock a call to create missing nodes
    [
      cluster['nodes'][2],
      cluster['nodes'][3],
      cluster['nodes'][4],
      {
        'name'   => nodes[5],
        'config' => {
          'cluster_config_specified' => true,
        }
      },
    ].each do |node|
      params = {
        'name'     => node['name'],
        'template' => node['template'],
        'config'   => node['config'],
        'url'      => node['url'],
      }

      expect_task('lima::start').be_called_times(1).with_params(params).always_return({})
    end

    # Mock a call to start existing but stopped node (see lima_list_res)
    nodes_to_stop = [ nodes[1] ]
    nodes_to_stop.each do |node|
      expect_task('lima::start').be_called_times(1).with_params({ 'name' => node }).always_return({})
    end

    expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")
    expect_out_verbose.with_params("Nodes to create: [#{[ nodes[2], nodes[3], nodes[4], nodes[5] ].join(', ')}]")
    expect_out_verbose.with_params("Nodes to start (1 nodes per batch): [#{nodes_to_stop.join(', ')}]")

    result = run_plan(plan, { 'name' => cluster_name, 'clusters' => clusters })

    expect(result.ok?).to be(true)
    expect(result.value.count).to eq(5)
  end
end
