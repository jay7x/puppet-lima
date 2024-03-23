# @summary Start the cluster of Lima VMs
# @param name
#   Cluster name
# @param jobs
#   How much VMs to start in parallel
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::start (
  String[1] $name,
  Integer[0] $jobs = 0,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = without_default_logging() || {
    run_plan('lima::clusters', name => $name, clusters => $clusters)
  }
  $tgt = get_target($target)

  $defined_nodes = $cluster['nodes'].map |$node| {
    $node ? {
      Hash    => $node['name'],
      String  => $node,
      default => undef,
    }
  }
  out::verbose("Defined nodes: ${defined_nodes}")

  # Get existing VMs
  $list_res = without_default_logging() || {
    run_task('lima::list', $tgt, names => $defined_nodes)
  }
  $lima_list = $list_res.find($target).value['list']

  # Check for missing nodes
  $missing_nodes = $defined_nodes - $lima_list.map |$x| { $x['name'] }
  if $missing_nodes.length > 0 {
    fail_plan("Some nodes are missing: ${missing_nodes}", 'lima/missing-nodes', missing_nodes => $missing_nodes)
  }

  $start_jobs = if $jobs > 0 {
    $jobs
  } else {
    if $tgt.facts.length < 1 {
      without_default_logging() || {
        run_plan('facts', $tgt, _catch_errors => true)
      }
    }
    $cpus = $tgt.facts.get('processors.count', 1)
    if $cpus < 4 { 1 } else { $cpus / 2 } # Assume every VM can consume up to 200% of a CPU core on start
  }

  # Start stopped nodes
  $stopped_nodes = $lima_list.filter |$x| { $x['status'] == 'Stopped' }.map |$x| { $x['name'] }
  out::verbose("Nodes to start (${start_jobs} nodes per batch): ${stopped_nodes}")

  # Run in batches of $start_jobs VMs in parallel
  $start_res = $stopped_nodes.slice($start_jobs).map |$batch| {
    $batch.parallelize |$node| {
      run_task('lima::start', $tgt, name => $node)
    }
  }

  return $start_res
}
