# @summary Create/start the cluster of Lima VMs
# @param name
#   Cluster name
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::start (
  String[1] $name,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = run_plan('lima::clusters', 'clusters' => $clusters, 'name' => $name)
  $tgt = get_target($target)

  $cluster_config = $cluster['nodes'].map |$node| {
    $n = $node ? {
      Hash => $node,
      String => { 'name' => $node },
      default => {},
    }

    # Use per-node configs first. Use cluster-wide configs otherwise.
    # Look for explicit config hash first then template then url.
    $cfg = [
      [$n['config'], 'config'],
      [$n['template'], 'template'],
      [$n['url'], 'url'],
      [$cluster['config'], 'config'],
      [$cluster['template'], 'template'],
      [$cluster['url'], 'url'],
    ].filter |$x| { $x[0] } # Delete undefined options

    unless $cfg.count >= 1 {
      fail("Node ${n['name']} has no config/template/url defined in the cluster configuration")
    }

    # Use first defined option ($cfg[0])
    ({ 'name' => $n['name'], $cfg[0][1] => $cfg[0][0] })
  }

  $defined_nodes = $cluster_config.map |$node| { $node['name'] }
  out::verbose("Defined nodes: ${defined_nodes}")

  # Collect and set the target's facts
  if empty(facts($tgt)) {
    without_default_logging() || {
      run_plan('facts', $tgt, '_catch_errors' => true)
    }
  }
  $cpus = facts($tgt).get('processors.count')
  $start_threads = if $cpus < 4 { 1 } else { $cpus / 2 } # Assume every VM can consume up to 200% of a CPU core on start

  # Get existing VMs
  $list_res = without_default_logging() || {
    run_task(
      'lima::list',
      $tgt,
      { names => $defined_nodes },
    )
  }
  $lima_config = $list_res.find($target).value['list']

  # Create missing nodes
  $missing_nodes = $defined_nodes - $lima_config.map |$x| { $x['name'] }
  out::verbose("Nodes to create: ${missing_nodes}")

  # `limactl start` cannot create multiple images in parallel
  # See https://github.com/lima-vm/lima/issues/1354
  # So creating VMs sequentially..
  $create_res = $missing_nodes.map |$node| {
    run_task(
      'lima::start',
      $tgt,
      "Create VM ${node}",
      'name' => $node,
      'template' => $cluster['template'],
      'config' => $cluster['config'],
      'url' => $cluster['url'],
    )
  }

  # Start existing but non-running nodes
  $stopped_nodes = $lima_config
  .filter |$x| { $x['status'] == 'Stopped' }
  .map |$x| { $x['name'] }
  out::verbose("Nodes to start (${start_threads} nodes per batch): ${stopped_nodes}")

  # Run in batches of $start_threads VMs in parallel
  $start_res = $stopped_nodes.slice($start_threads).map |$batch| {
    $batch.parallelize |$node| {
      run_task(
        'lima::start',
        $tgt,
        "Start VM ${node}",
        'name' => $node,
      )
    }
  }

  return flatten($create_res + $start_res)
}
