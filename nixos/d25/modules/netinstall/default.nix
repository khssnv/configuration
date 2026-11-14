{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.netinstall;
  manageFirewall = cfg.openFirewall && config.networking.firewall.enable;
  nftables = config.networking.nftables.enable;
  firewallUnit = if nftables then "nftables.service" else "firewall.service";

  firewall = pkgs.writeShellApplication {
    name = "netinstall-firewall";
    runtimeInputs =
      if nftables then
        [
          pkgs.nftables
          pkgs.jq
        ]
      else
        [ pkgs.iptables ];
    text = ''
      action=$1
      tag=$2
    ''
    + (
      if nftables then
        ''
          case "$action" in
            open)
              nft add rule inet nixos-fw input-allow \
                meta nfproto ipv4 udp dport '{ 67, 69, 5000 }' accept comment "\"$tag\""
              ;;
            close)
              # A firewall restart may already have removed our rule.
              if nft list table inet nixos-fw >/dev/null 2>&1; then
                rules=$(nft --json --handle list chain inet nixos-fw input-allow)
                handles=$(jq -r --arg tag "$tag" \
                  '.nftables[] | .rule? | select(.comment == $tag) | .handle' <<< "$rules")
                for handle in $handles; do
                  nft delete rule inet nixos-fw input-allow handle "$handle"
                done
              fi
              ;;
            *) exit 2 ;;
          esac
        ''
      else
        ''
          # Netinstall uses IPv4. The comment identifies this invocation's rule.
          rule=(-p udp -m multiport --dports "67,69,5000" -m comment --comment "$tag" -j nixos-fw-accept)
          case "$action" in
            open) iptables -w -I nixos-fw "''${rule[@]}" ;;
            close)
              if iptables -w -C nixos-fw "''${rule[@]}" 2>/dev/null; then
                iptables -w -D nixos-fw "''${rule[@]}"
              fi
              ;;
            *) exit 2 ;;
          esac
        ''
    );
  };

  launcher = pkgs.writeShellApplication {
    name = "netinstall-cli";
    runtimeInputs = [
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      if (( EUID != 0 )); then
        echo 'Run netinstall-cli as root.' >&2
        exit 1
      fi

      unit="netinstall-cli-$(uuidgen).service"
      # The service owns firewall cleanup, including failed starts and crashes.
      # Stop it too if the terminal client exits before the service does.
      cleanup() {
        systemctl stop "$unit" >/dev/null 2>&1 || true
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM
      trap 'exit 129' HUP

      properties=(
        ${lib.optionalString manageFirewall ''
          --property=After=${firewallUnit}
          --property=BindsTo=${firewallUnit}
          --property="ExecStartPre=${lib.getExe firewall} open $unit"
          --property="ExecStopPost=${lib.getExe firewall} close $unit"
        ''}
      )
      systemd-run --unit="$unit" --quiet --collect --wait --pty --pipe \
        --service-type=exec --same-dir --expand-environment=no \
        "''${properties[@]}" \
        -- ${lib.getExe cfg.package} "$@"
    '';
  };
in
{
  options.programs.netinstall = {
    enable = lib.mkEnableOption "MikroTik Netinstall CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/netinstall-cli.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/netinstall-cli.nix { }";
      description = "The unwrapped Netinstall CLI package.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether the netinstall-cli launcher temporarily allows incoming IPv4
        UDP traffic on ports 67, 69 and 5000 while its systemd service runs.
        Each invocation removes its own rules on exit, including failed starts.
        Rules apply to all interfaces. No ports are opened at boot.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ launcher ];
  };
}
