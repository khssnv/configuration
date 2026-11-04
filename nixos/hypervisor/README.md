# hypervisor

NixOS-based hypervisor for KVM/libvirt VMs and containers.

## Storage

Hosts data stored remotely on TrueNAS with SATA SSD and SATA HDD pools.

### VM disks

- TrueNAS Mapall User / Group: hypervisor-qemu-libvirtd.
  All client UID/GID values map to 3301:3301.
- NixOS mount point: /var/lib/libvirt/images.
  NFS 4.2 with systemd automount.
- QEMU runs as qemu-libvirtd (301:301).

## TODO

- Restrict the TrueNAS NFS export `/mnt/sata-ssd/hypervisor/libvirt/images`
  to the hypervisor storage interface address. Currently, no client
  IP or network restrictions are configured. The ens19 DHCP address
  `192.168.1.235` is assumed to be reserved; verify before restricting.
