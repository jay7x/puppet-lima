# lima

Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Inventory plugin usage](#inventory-plugin-usage)
4. [Cluster management plans usage](#cluster-management-plans-usage)

## Description

The Lima module is a "glue" between Puppet Bolt and [`lima`](https://github.com/lima-vm/lima)

## Requirements

You will need to have installed `limactl` on the system you wish to run Bolt from.

## Inventory plugin usage

The `resolve_reference` task supports looking up target objects from a `limactl list` output. It accepts following parameters:

- `limactl`: Location of the `limactl` binary if not in `$PATH`.
- `only_matching_names`: Only VM with names matching this regex will be included into the inventory. This regex is passed to `Regexp.new()` as a string.
- `except_matching_names`: VMs with names matching this regex will be excluded from the inventory. This regex is passed to `Regexp.new()` as a string.

**NOTE 1:** Only **running** VMs are returned.

**NOTE 2:** If both `only_matching_names` and `except_matching_names` are specified then only VMs matching `only_matching_names` and not matching `except_matching_names` are returned.

### Examples

```yaml
groups:
  - name: lima-vms
    targets:
      - _plugin: lima
        except_matching_names: '^default'
```

## Cluster management plans usage

This module provides a way to define and manage clusters of Lima VMs. It's expected to define clusters in the [plan_hierarchy of your Bolt project's Hiera](https://www.puppet.com/docs/bolt/latest/hiera.html#outside-apply-blocks).

Below is the example of a Hiera file under `plan_hierarchy`:

```yaml
---
# Leverage YAML features to define templates required
x-ubuntu2004: &ubuntu2004
  images:
  - location: "https://cloud-images.ubuntu.com/releases/20.04/release-20230117/ubuntu-20.04-server-cloudimg-amd64.img"
    arch: "x86_64"
    digest: "sha256:3e44e9f886eba6b91662086d24028894bbe320c1de89be5c091019fedf9c5ce6"
  - location: "https://cloud-images.ubuntu.com/releases/20.04/release-20230117/ubuntu-20.04-server-cloudimg-arm64.img"
    arch: "aarch64"
    digest: "sha256:4ea4700f7b1de194a2f6bf760b911ea3071e0309fcea14d3a465a3323d57c60e"
  - location: "https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img"
    arch: "x86_64"
  - location: "https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-arm64.img"
    arch: "aarch64"
  mounts:
  - location: "~"

# Cluster definitions
lima::clusters:
  example: # `example` cluster
    nodes:
      - example1
        template: ubuntu  # Use latest ubuntu version on this VM
      - example2
      - example3
    config:
      <<: *ubuntu2004
```

Now when you have some clusters defined you can use cluster management plans to start/stop/delete a cluster. E.g.:

```bash
# Start the cluster (create example[123] VMs)
bolt plan run lima::cluster::start name=example
# Stop the cluster (stop example[123] VMs)
bolt plan run lima::cluster::stop name=example
# Delete the cluster (delete example[123] VMs)
bolt plan run lima::cluster::delete name=example
```

## Reference

Reference documentation for the module is generated using
[puppet-strings](https://puppet.com/docs/puppet/latest/puppet_strings.html) and available in [REFERENCE.md](REFERENCE.md)
