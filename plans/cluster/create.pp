# @summary Create the cluster of Lima VMs
# @param name
#   Cluster name
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @param target
#   The host to run the limactl on
plan lima::cluster::create (
  String[1] $name,
  Optional[Hash] $clusters = undef,
  TargetSpec $target = 'localhost',
) {
  $cluster = run_plan('lima::clusters', name => $name, clusters => $clusters)
  $tgt = get_target($target)

  $cluster_config = $cluster['nodes'].reduce({}) |$memo, $node| {
    $n = $node ? {
      Hash => $node,
      String => { 'name' => $node },
      default => {},
    }

    # Use per-node configs first. Use cluster-wide configs otherwise.
    # Look for explicit config hash then url.
    # Keeping it non-DRY for readability
    $cfg = [
      ['config', $n['config']],
      ['url', $n['url']],
      ['config', $cluster['config']],
      ['url', $cluster['url']],
    ].filter |$x| { $x[1] } # Delete undefined options

    unless $cfg.length >= 1 {
      fail("Node ${n['name']} has no config/url defined in the cluster configuration")
    }

    # Use first defined option ($cfg[0])
    $memo + { $n['name'] => { $cfg[0][0] => $cfg[0][1] } }
  }

  $defined_nodes = $cluster_config.keys
  out::verbose("Defined nodes: ${defined_nodes}")

  # Get existing VMs
  $list_res = without_default_logging() || {
    run_task('lima::list', $tgt, names => $defined_nodes)
  }
  $lima_config = $list_res.find($target).value['list']

  # Create missing nodes
  $missing_nodes = $defined_nodes - $lima_config.map |$x| { $x['name'] }
  out::verbose("Nodes to create: ${missing_nodes}")

  # `limactl create` cannot create multiple images in parallel
  # See https://github.com/lima-vm/lima/issues/1354
  # So creating VMs sequentially..
  $create_res = $missing_nodes.map |$node| {
    run_task('lima::create', $tgt, {
        name   => $node,
        config => $cluster_config[$node]['config'],
        url    => $cluster_config[$node]['url'],
    })
  }

  return $create_res
}
