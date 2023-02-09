# @summary Return the cluster definition
# @param name
#   Cluster name
# @param clusters
#   Hash of all defined clusters. Populated from Hiera usually.
# @return [Hash] Return the named cluster definition
plan lima::clusters (
  String[1] $name,
  Hash $clusters = lookup('lima::clusters', 'default_value' => {}),
) {
  return $clusters[$name].lest || {
    fail_plan("Cluster '${name}' is not defined", 'lima/undefined-cluster')
  }
}
