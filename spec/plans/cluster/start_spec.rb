# frozen_string_literal: true

require 'spec_helper'

describe 'lima::cluster::start' do
  let(:plan) { 'lima::cluster::start' }
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
          nodes[2],
          {
            'name' => nodes[3],
          },
          {
            'name' => nodes[4],
          },
        ],
      },
    }
  end
  let(:facts) { { 'processors': { 'count': 1 } } }
  let(:lima_list_res) do
    {
      'list': [
        { 'name': nodes[0], 'status': 'Stopped' },
        { 'name': nodes[1], 'status': 'Stopped' },
        { 'name': nodes[2], 'status': 'Running' },
        { 'name': nodes[3], 'status': 'Stopped' },
        { 'name': nodes[4], 'status': 'Stopped' },
      ]
    }
  end

  context 'when wrong cluster name specified' do
    it 'fails' do
      result = run_plan(plan, 'name' => 'nonexistent', 'clusters' => clusters)

      expect(result.ok?).to be(false)
      expect(result.value.msg).to match(%r{Cluster 'nonexistent' is not defined})
    end
  end

  context 'when some nodes are missing' do
    let(:lima_list_res) { { 'list': [] } }

    it 'fails' do
      allow_plan('lima::clusters').always_return(clusters[cluster_name])
      expect_task('lima::list').be_called_times(1).always_return(lima_list_res)
      expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")

      result = run_plan(plan, 'name' => cluster_name, 'clusters' => clusters)

      expect(result.ok?).to be(false)
      expect(result.value.msg).to match(%r{Some nodes are missing: \[#{nodes.join(', ')}\]})
    end
  end

  context 'when everything is defined properly' do
    it 'creates and runs the cluster' do
      allow_task('facts').always_return(facts)

      expect_plan('lima::clusters').always_return(clusters[cluster_name])
      expect_task('lima::list').be_called_times(1).always_return(lima_list_res)
      expect_out_verbose.with_params("Defined nodes: [#{nodes.join(', ')}]")

      # Mock a call to start existing but stopped node (see lima_list_res)
      nodes_to_start = lima_list_res[:list].filter { |n| n[:status] == 'Stopped' }.map { |n| n[:name] }
      nodes_to_start.each do |node|
        expect_task('lima::start').be_called_times(1).with_params('name' => node).always_return(start: true)
      end
      expect_out_verbose.with_params("Nodes to start (1 nodes per batch): [#{nodes_to_start.join(', ')}]")

      result = run_plan(plan, 'name' => cluster_name, 'clusters' => clusters)

      expect(result.ok?).to be(true)
      expect(result.value.count).to eq(nodes_to_start.length)
    end
  end
end
