# config-dump

`config-dump` was created to preserve the initial factory configuration of RAE
robots before network setup or other configuration changes. It stores collected
observations as JSON snapshots and a generated Markdown configuration dump.

`collect.py` reads allowlisted RAE parameters and writes JSON. `render.py` converts
saved snapshots in `rae/config-dump/data/` to `rae/init-config-dump.md`. Both use only
the Python standard library and support Python 3.8 or newer.

Run the computer-side examples below from `rae/`. Use the scripts on the computer
that is connected to the robot. Physical names `rae-alpha` and `rae-beta` are
operator selections, not automatic identification: factory robots share hostname
`rae` and address `192.168.197.55`.

## Collect through Ansible

Before network setup, connect exactly one factory-reset robot USB link:

```console
ansible-playbook -i inventory.yml 00-config-dump.yml --limit rae-beta -e initial_host=192.168.197.55
```

This collects both sections, atomically replaces `config-dump/data/rae-beta-common.json`
and `config-dump/data/rae-beta-unit.json`, then regenerates `init-config-dump.md` using all
saved snapshots. Select `rae-alpha` instead for the physical Alpha.

The playbook uses `ansible.builtin.raw` to run the collector source with RAE's
Python 3.8. It does not install a script or invoke Ansible Python modules on RAE.
Ansible handles the SSH connection; controller commands add metadata and save
files locally. SSH configuration and private keys are excluded from this
passwordless transport. `--check` validates the selection and skips collection
and local file generation.

Optional extra variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `initial_host` | Inventory USB address | Initial address, usually `192.168.197.55` after reset |
| `collect_section` | `all` | `common`, `unit` or `all`; unselected saved sections remain unchanged |
| `snapshot_dir` | `rae/config-dump/data` | Controller directory for JSON inputs and outputs |
| `report_path` | `rae/init-config-dump.md` | Generated Markdown path |

The playbook also works with the configured inventory USB address when
`initial_host` is omitted. That captures the current managed configuration.
To keep those observations separate from the factory baseline:

```console
ansible-playbook -i inventory.yml 00-config-dump.yml --limit rae-beta -e snapshot_dir=/tmp/rae-current -e report_path=/tmp/rae-current.md
```

## Collect manually over SSH

```console
python3 config-dump/collect.py common --host 192.168.197.55 --unit-label rae-beta --output config-dump/data/rae-beta-common.json
python3 config-dump/collect.py unit --host 192.168.197.55 --unit-label rae-beta --output config-dump/data/rae-beta-unit.json
python3 config-dump/render.py
```

`--host` accepts an IP address. This transport uses passwordless root SSH, disables
key/password authentication, reads no local SSH configuration or keys and stores
no host keys. Use it on the direct trusted USB link. Python 3, SSH and `ip` are
needed on the computer; only Python 3.8 and the probed vendor tools are needed on
RAE. No additional Python packages are required.

Without `--output`, JSON is printed to stdout. Prefer `--output` to shell
redirection when replacing saved snapshots: SSH or JSON errors leave the old
snapshot intact. Output directories are created as needed.

## Run directly on RAE or from another caller

When the collector source is already available on RAE:

```console
python3 collect.py common
python3 collect.py unit
```

These commands return raw JSON with `section` and `probes`. They do not add a
timestamp from the unsynchronized robot clock. The playbook runs this same mode
without installing the file. Each probe contains its exact shell `command`,
`returncode`, `stdout` and `stderr`. A timeout adds `error` and preserves partial
stdout/stderr. Probes run independently, with 30 seconds per probe. A probe's exit
status is the final shell command's status; inspect stderr too, since an earlier
command may fail while a later one succeeds. Missing optional tools and inactive
services are evidence, rather than fatal collection errors.

Save the raw JSON on the computer and annotate it there:

```console
python3 config-dump/collect.py annotate --unit-label rae-beta --target 192.168.197.55 --output config-dump/data/rae-beta-unit.json < /tmp/rae-beta-unit-raw.json
```

`annotate` reads stdin and makes no SSH connection. It adds `unit`, `ssh_target`,
`collected_at_utc` and `timestamp_source`. For a `unit` snapshot it also records
`controller_link`: the route, IPv4 addresses and network driver used to reach RAE.
This is the computer's connection, not necessarily USB if another address is used.
Missing `ip` or a route error is recorded without discarding robot observations.

## Generate Markdown without a robot

```console
python3 config-dump/render.py
python3 config-dump/render.py --snapshots config-dump/data --output /tmp/rae-init-config-dump.md
```

Defaults are resolved relative to the script location, so the first command also
works from another working directory. The renderer reads `rae-*.json` in the
selected snapshot directory, identifies each by its `unit` and `section`, and
rejects duplicate or malformed snapshot entries. Computer connection evidence is
stored in `controller_link`. Units without a unit snapshot are marked as pending.

The report contains unit tables and collapsible command/stdout/stderr blocks for
every probe. Probe errors and unavailable fields remain visible. Markdown fences
adapt to backticks in output; trailing terminal whitespace is omitted from Markdown
and retained in JSON. Generation is deterministic for identical inputs:
no current timestamp is added. Identical output is left untouched; changed output
is replaced atomically. The script prints `changed:` or `unchanged:` for Ansible.
Edit JSON inputs or the renderer and regenerate; direct edits to `init-config-dump.md`
are overwritten. Do not add invented output to replace a missing observation.

## Collection boundaries

The collector changes no robot configuration. It excludes password databases,
SSH keys/authorized keys, hostapd/WPA credentials, Mender/RobotHub configuration,
environment scripts and EEPROM contents. Some directory listings include filenames
of excluded files; their contents are not read.

Battery `charge_full` is a learned gauge estimate. Memory usage, disk usage,
service states, ports and the active A/B slot are observations, not fixed defaults.
A snapshot does not establish whether a factory reset occurred; collect the
baseline before network setup and keep managed snapshots in a separate directory.

## Verification

From `rae/`:

```console
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s config-dump -p 'test_*.py'
ansible-playbook -i inventory.yml 00-config-dump.yml --limit rae-beta --syntax-check
```
