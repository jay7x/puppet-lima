# @summary Stop the cluster of Lima VMs
# @param name
#   Cluster name
# @param force
#   Forcibly stop the processes
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::stop (
  String[1] $name,
  Boolean $force = false,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = run_plan('lima::clusters', name => $name, clusters => $clusters)

  $defined_nodes = $cluster['nodes'].map |$node| {
    $node ? {
      Hash => $node['name'],
      String => $node,
      default => undef,
    }
  }
  out::verbose("Defined nodes: ${defined_nodes}")

  # Get existing VMs
  $list_res = without_default_logging() || {
    run_task('lima::list', $target, names => $defined_nodes)
  }
  $lima_config = $list_res.find($target).value['list']

  # Stop every existing node when in force mode
  # Otherwise stop running nodes only
  $nodes_to_stop = $force ? {
    true    => $lima_config,
    default => $lima_config.filter |$x| { $x['status'] == 'Running' },
  }.map |$x| { $x['name'] }
  out::verbose("Nodes to stop: ${nodes_to_stop}")

  # Stop nodes
  $stop_res = parallelize ($nodes_to_stop) |$node| {
    run_task('lima::stop', $target, {
        name  => $node,
        force => $force,
    })
  }

  return $stop_res
}
