# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::create' do
  let(:plan) { 'lima::cluster::create' }
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
      'example' => {
        'nodes' => [
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
      'misconfigured' => {
        'nodes' => [
          nodes[2],
        ],
      }
    }
  end
  let(:cluster_name) { 'example' }
  let(:lima_list_res) do
    {
      'list': [
        { 'name': nodes[0], 'status': 'Running' },
        { 'name': nodes[1], 'status': 'Stopped' },
      ]
    }
  end
  let(:nodes_to_create) { [nodes[2], nodes[3], nodes[4]] }
  let(:plan_params) { { 'name' => cluster_name, 'clusters' => clusters } }

  context 'with non-existent cluster' do
    let(:cluster_name) { 'nonexistent' }

    it 'fails' do
      result = run_plan(plan, plan_params)

      expect(result.ok?).to be(false)
      expect(result.value.msg).to match(%r{Cluster 'nonexistent' is not defined})
    end
  end

  context 'with misconfigured nodes' do
    let(:cluster_name) { 'misconfigured' }

    it 'fails' do
      expect_plan('lima::clusters').always_return(clusters[cluster_name])

      result = run_plan(plan, plan_params)

      expect(result.ok?).to be(false)
      expect(result.value.kind).to match('lima/misconfigured-node')
      expect(result.value.msg).to match(%r{Node #{nodes[2]} has no config/url defined})
    end
  end

  context 'with existing cluster' do
    let(:node_params) do
      {
        nodes[2] => clusters[cluster_name]['nodes'][2],
        nodes[3] => clusters[cluster_name]['nodes'][3],
        nodes[4] => {
          'name'   => nodes[4],
          'config' => {
            'cluster_config_specified' => true,
          }
        },
      }
    end

    before :each do
      expect_plan('lima::clusters').always_return(clusters[cluster_name])
      expect_task('lima::list').be_called_times(1).always_return(lima_list_res)
      nodes_to_create.each do |node|
        np = node_params[node]
        params = {
          'name'     => np['name'],
          'config'   => np['config'],
          'url'      => np['url'],
        }

        expect_task('lima::create').be_called_times(1).with_params(params).always_return(create: true)
      end
      expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")
      expect_out_verbose.with_params("Nodes to create: [#{nodes_to_create.join(', ')}]")
    end

    it 'creates the cluster' do
      result = run_plan(plan, plan_params)

      expect(result.ok?).to be(true)
      expect(result.value.count).to eq(3)
    end
  end
end
