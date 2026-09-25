# Nextcloud

Nextcloud AIO on a Proxmox VE VM without public IP, published through a VPS.

```text
Internet ──443/tcp───▶ gateway      VPS with public IP, nginx TCP proxy
                          │
                          │ WireGuard, initiated by nextcloud
                          ▼
LAN ─────8080/tcp────▶ nextcloud    Proxmox VE VM, Nextcloud AIO, AIO interface on 8080
                          │
                          │ NFS v4.2
                          ▼
                       TrueNAS      datadir on HDD, appdata and database on SSD
```

## Requirements

- Steps from [README](README.md) are done for `gateway` and `nextcloud` hosts.
- VPS is in the `gateway` group of [inventories/static.yml](inventories/static.yml).
- Proxmox VE VM is named `nextcloud`, the name binds [inventories/host_vars/nextcloud.yml](inventories/host_vars/nextcloud.yml).
- VM has a single IP address in `nextcloud_admin_cidr`, SSH and AIO interface are available on it.
- DNS A record of the Nextcloud domain points to `gateway` public IP. AIO validates the domain and obtains TLS certificate through it.

### TrueNAS

TrueNAS provides three NFS exports, one per storage kind:

| Export                             | Disk | Content               | Used on the VM as                                   |
| ---------------------------------- | ---- | --------------------- | --------------------------------------------------- |
| `/mnt/sata-hdd/nextcloud/datadir`  | HDD  | Nextcloud datadir     | `/mnt/nextcloud/datadir`                            |
| `/mnt/sata-ssd/nextcloud/appdata`  | SSD  | Nextcloud `appdata_*` | `/mnt/nextcloud/appdata`, bind mounted into datadir |
| `/mnt/sata-ssd/nextcloud/database` | SSD  | PostgreSQL data       | Docker volume `nextcloud_aio_database`              |

Expectations:

- Exports are empty before the first deployment.
- Exports are available over NFS v4.2 from the `nextcloud` VM, `truenas.lan` resolves on the VM.
- `root` of the VM is not squashed: playbook `04` creates the bind mount point in datadir, step 3 copies appdata as `root` preserving ownership, Docker prepares the database volume as `root`.
- datadir and appdata content is owned by `33:0` with `750` permissions (`www-data` in the Nextcloud container), as AIO requires.
- database content is owned by `999:999` (PostgreSQL user in the AIO database container), which can change permissions of its data directory.
- The VM sees numeric owners as is: `ls -ln` shows `33`, `999`, not `65534` (`nobody`).

## Configuration

- [inventories/host_vars/nextcloud.yml](inventories/host_vars/nextcloud.yml)
  - `nextcloud_nfs_server`: TrueNAS address.
  - `nfs_share_mounts[].location`, `nextcloud_aio_database_nfs_export`: export paths.
  - `nextcloud_admin_cidr`: VM LAN, allowed for SSH and used to pick the AIO interface address.
  - `wireguard_addresses`: VM tunnel address.
- [inventories/group_vars/gateway.yml](inventories/group_vars/gateway.yml)
  - `wireguard_addresses`, `wireguard_port`: `gateway` tunnel address and port.

## Deployment

1. Run `ansible/playbooks/03-nextcloud-pre.yml` to expose nextcloud VM ports on a VPS with public IP, mount NFS shares and start Nextcloud AIO.

    ```console
    ansible-playbook -i inventories playbooks/03-nextcloud-pre.yml
    ```

1. Install Nextcloud in AIO interface.
    1. Open `https://<nextcloud-vm-lan-ip>:8080`, the VM IP is shown in Proxmox VE UI. Use the IP, not a domain, as HSTS may block access later. Accept the self-signed certificate.
    1. Save the passphrase, it is the only way to log in to AIO interface.
    1. Enter the Nextcloud domain, AIO validates it through `gateway`.
    1. Disable Talk in optional containers, `gateway` does not forward its port `3478`.
    1. Start containers and wait until Nextcloud is running.

1. Move appdata folder to SSD share. Nextcloud keeps app data (previews, caches, app files) in `appdata_<instanceid>` inside datadir, which is on HDD. Run commands on `nextcloud` VM.
    1. Stop containers in AIO interface, so appdata does not change during the copy.
    1. Find the appdata folder name, `<instanceid>` is used in the next commands.

        ```console
        ls -d /mnt/nextcloud/datadir/appdata_*
        ```

    1. Copy appdata folder content to SSD share. The trailing slash copies the folder content, not the folder itself. `-a` preserves ownership and permissions.

        ```console
        sudo rsync -a /mnt/nextcloud/datadir/appdata_<instanceid>/ /mnt/nextcloud/appdata/
        ```

    1. Rename the original folder to keep it as a backup and free its path for the bind mount.

        ```console
        sudo mv /mnt/nextcloud/datadir/appdata_<instanceid> /mnt/nextcloud/datadir/appdata_<instanceid>-backup
        ```

    1. Run `ansible/playbooks/04-nextcloud-post.yml` to bind mount the SSD share in place of the appdata folder.

        ```console
        ansible-playbook -i inventories playbooks/04-nextcloud-post.yml
        ```

    1. Start containers in AIO interface.

    See:
    - https://github.com/nextcloud/all-in-one/tree/V13.2.1#how-to-change-the-default-location-of-nextclouds-datadir
    - https://github.com/nextcloud/all-in-one/tree/V13.2.1#how-to-move-the-appdata-folder-from-the-datadir-to-an-ssd-to-improve-the-performance

1. Verify that storage is mounted before Nextcloud starts after a reboot.
    1. Reboot `nextcloud` VM.

        ```console
        sudo reboot
        ```

    1. Check that systemd did not break mount ordering, expect no output.

        ```console
        journalctl -b | grep -i "ordering cycle"
        ```

    1. Check that appdata share is mounted in datadir, expect `truenas.lan:/mnt/sata-ssd/nextcloud/appdata` as `SOURCE`.

        ```console
        findmnt /mnt/nextcloud/datadir/appdata_<instanceid>
        ```

    1. Open `https://<nextcloud-domain>` and log in.
    1. Remove appdata backup.

        ```console
        sudo rm -r /mnt/nextcloud/datadir/appdata_<instanceid>-backup
        ```

## Notes

- NFS mounts as the docker "data-root" is not supported, see https://docs.docker.com/engine/security/rootless/troubleshoot#known-limitations.
- [How to properly reset the instance?](https://github.com/nextcloud/all-in-one/tree/V13.2.1#how-to-properly-reset-the-instance)

## TODO

- Add datasets and shares creation documentation.
- Remote borg backups.
- Explore if deployment to NixOS could provide higher level of automation and reliability.
