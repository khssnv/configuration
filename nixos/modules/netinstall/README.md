# Netinstall

[default.nix](default.nix) installs a `netinstall-cli` launcher via
`programs.netinstall.enable`. Run it as root with the usual Netinstall
arguments, for example:

```sh
sudo netinstall-cli -i enp3s0 -r ./routeros-7.25.1-arm64.npk
```

Replace the interface, package version and architecture with your device's
values. `-r` reinstalls RouterOS and applies the default configuration.

The launcher creates a transient systemd service, preserves the working
directory and literal arguments, and connects the output to the terminal.
`Ctrl+C` stops the program. Redirected input/output uses pipes instead of a PTY.
The command returns the service's exit status. No service starts at boot.

With `programs.netinstall.openFirewall` enabled, the service opens IPv4 UDP 67
(BOOTP), 69 (TFTP), and 5000 (Netinstall) on all interfaces immediately before
starting Netinstall. Its `ExecStopPost` removes only that invocation's rules
after normal completion, a crash, a failed start or a stop. Separate invocations
have independent rules. Both NixOS iptables and nftables backends are supported.
Stopping or restarting the firewall stops the service; reloading firewall rules
may remove its temporary rules, requiring a new run. An interrupted cleanup can
leave rules behind until the firewall is restarted. Existing conntrack entries
can outlive rule removal.

Setting `openFirewall = false` disables automatic firewall changes. The raw
package remains available through `programs.netinstall.package`, but direct
execution of that binary bypasses the launcher's firewall management.

The port list comes from a
[Linux Netinstall report on MikroTik's forum](https://forum.mikrotik.com/t/netinstall-instructions/123631/13).
The current vendor manual does not enumerate the Linux firewall ports; verify a
complete installation with the packaged version before relying on these rules.
The
[vendor recommends](https://manual.mikrotik.com/docs/getting-started/installation-and-upgrade/netinstall/)
a dedicated interface and an isolated installation segment. Select that
interface with `-i` and restrict the target with `--mac`, as described in the
[Linux manual](https://manual.mikrotik.com/docs/getting-started/installation-and-upgrade/netinstall/netinstall-linux/).
The `-i` argument selects the application's interface; firewall rules themselves
are not restricted to it.

## Security

Subjective additional-risk scale: 0 = no added exposure; 1 = unacceptable
exposure. These scores are judgments, not measured attack probabilities.

- **0.0 while stopped:** this module leaves no permanent port allowances.
- **0.6 while Netinstall runs on an untrusted network:** the tool runs as root
  and processes network input. A vulnerability could affect the host; BOOTP
  and TFTP do not provide peer authentication. Other devices in Etherboot mode
  could also be reinstalled unless the target is restricted.

The pinned NixOS Winbox module permanently allows UDP 5678, 20561, and
40000–50000 when its `openFirewall` option is enabled. This module's three ports
are allowed only for the lifetime of a launched service. Port count alone does
not establish lower risk; use an isolated installation segment.

## Testing

Run manually from the repository root on Linux. Requires Nix, Python 3,
`unshare`, `ip`, and permission to create user and network namespaces.

Build and test both firewall backends (`false` = iptables, `true` = nftables):

```sh
for useNftables in false true; do
  nix build --impure --arg useNftables "$useNftables" --expr '
    { useNftables }:
    let
      flake = builtins.getFlake (toString ./nixos);
      host = flake.nixosConfigurations.d25.extendModules {
        modules = [ ./nixos/modules/netinstall {
          programs.netinstall = {
            enable = true;
            openFirewall = true;
          };
          networking.nftables.enable =
            flake.inputs.nixpkgs.lib.mkForce useNftables;
        } ];
      };
    in builtins.head (builtins.filter
      (p: p.name == "netinstall-cli") host.config.environment.systemPackages)
  ' --out-link "/tmp/netinstall-test-$useNftables" || break

  python3 nixos/modules/netinstall/test-firewall.py \
    "/tmp/netinstall-test-$useNftables/bin/netinstall-cli" || break
done
```

Each successful test prints `PASS: ...`. The test checks UDP ports 67, 69 and
5000, rule removal, independent concurrent invocations, preservation of an
unrelated rule, and cleanup after a firewall reset.

The test creates an isolated network namespace and does not change the host
firewall, run Netinstall, or install RouterOS. It tests the firewall helper; the
systemd lifecycle and `Ctrl+C` require a separate integration test. Nothing runs
automatically during system builds or normal Netinstall use.
