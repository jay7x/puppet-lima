# @summary Delete the cluster of Lima VMs
# @param name
#   Cluster name
# @param force
#   Forcibly stop the processes
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::delete (
  String[1] $name,
  Boolean $force = false,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = without_default_logging() || {
    run_plan('lima::clusters', name => $name, clusters => $clusters)
  }

  $defined_nodes = $cluster['nodes'].map |$node| {
    $node ? {
      Hash => $node['name'],
      String => $node,
      default => undef,
    }
  }
  out::verbose("Nodes to delete: ${defined_nodes}")

  return run_task('lima::delete', $target, {
      names => $defined_nodes,
      force => $force,
  })
}
