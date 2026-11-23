{
  lib,
  pkgs,
  userName,
  ...
}:

let
  guestNetworkBridge = "virbr-guest";
  guestNetworkGateway = "192.168.123.1"; # `default` network is `192.168.122.0/24`.
in
{
  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false; # limit guest process privileges
    qemu.swtpm.enable = true; # TPM 2.0 support for Windows 11
  };

  users.users.${userName}.extraGroups = [ "libvirtd" ];

  # Guest network.
  networking.firewall.interfaces.${guestNetworkBridge}.allowedUDPPorts = [ 67 ]; # allow DHCP
  systemd.services.libvirt-guest-network =
    let
      virsh = "${pkgs.libvirt}/bin/virsh --connect qemu:///system";
      guestUUID = "20499015-9253-4aba-924d-f480c1f50545";
      network = pkgs.writeText "libvirt-guest.xml" ''
        <network>
          <name>guest</name>
          <uuid>${guestUUID}</uuid>
          <forward mode="nat"/>
          <bridge name="${guestNetworkBridge}"/>
          <port isolated="yes"/>
          <ip address="${guestNetworkGateway}" prefix="24">
            <dhcp>
              <range start="192.168.123.100" end="192.168.123.250"/>
            </dhcp>
          </ip>
        </network>
      '';
    in
    {
      description = "Libvirt guest network";
      wantedBy = [
        "multi-user.target"
        "libvirtd.service"
      ];
      partOf = [ "libvirtd.service" ];
      bindsTo = [ "virbr-guest-firewall.service" ];
      # Install isolation rules before creating the guest bridge.
      requires = [ "libvirtd.service" ];
      after = [
        "libvirtd.service"
        "virbr-guest-firewall.service"
        "firewall.service"
      ];
      before = [ "libvirt-guests.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${virsh} net-create --validate ${network}";
      };
      preStop = ''
        activeNetworks=$(${virsh} net-list --transient --uuid)
        if grep -Fxq ${guestUUID} <<< "$activeNetworks"; then
          ${virsh} net-destroy ${guestUUID}
        fi
      '';
    };

  # Guest network firewall.
  systemd.services.virbr-guest-firewall =
    let
      nft = lib.getExe pkgs.nftables;
      rules = pkgs.writeText "virbr-guest-firewall.nft" ''
        define guestNetworkBridge = "${guestNetworkBridge}"
        define guestNetworkGateway = ${guestNetworkGateway}

        ${builtins.readFile ./virbr-guest-firewall.nft}
      '';
    in
    {
      description = "Internet-only access for the libvirt guest network";
      reloadIfChanged = true;
      # ExecStop is omitted so restrictions remain if stopping the guest network fails.
      # The dedicated table is replaced on start/reload and cleared on reboot.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${nft} -f ${rules}";
        ExecReload = "${nft} -f ${rules}";
      };
    };
}
