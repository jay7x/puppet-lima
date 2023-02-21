# @summary Stop the cluster of Lima VMs
# @param name
#   Cluster name
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::stop (
  String[1] $name,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = run_plan('lima::clusters', 'name' => $name, 'clusters' => $clusters)

  $defined_nodes = $cluster['nodes'].map |$node| {
    $node ? {
      Hash => $node['name'],
      String => $node,
      default => undef,
    }
  }
  out::verbose("Defined nodes: ${defined_nodes}")

  $list_res = without_default_logging() || {
    run_task(
      'lima::list',
      $target,
      'names' => $defined_nodes,
    )
  }
  $running_nodes = $list_res.find($target).value['list']
  .filter |$x| { $x['status'] == 'Running' }
  .map |$x| { $x['name'] }
  out::verbose("Nodes to stop: ${running_nodes}")

  # Stop running nodes
  $stop_res = parallelize ($running_nodes) |$node| {
    run_task(
      'lima::stop',
      $target,
      'name' => $node,
    )
  }

  return $stop_res
}
