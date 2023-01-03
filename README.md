# lima

Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage](#usage)

## Description

The Lima module is a "glue" between Puppet Bolt and [`lima`](https://github.com/lima-vm/lima)

Currently just the Bolt inventory plugin is implemented.

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

## Tasks

At the moment there are no other tasks implemented except the inventory plugin (`resolve_reference`). Tasks to be implemented:

- `lima::start`: Creates and runs a VM
- `lima::stop`: Stops a VM
- `lima::delete`: Deletes a VM
