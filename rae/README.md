# rae

Luxonis RAE robots configuration. Vendor setup instructions: <https://docs.luxonis.com/hardware/rae/get-started/>.

## Network setup

After each factory reset, configure networking on one robot at a time. Keep at
most one factory-reset USB link active: both robots use `192.168.197.55`.
Select the physical robot yourself; `--limit` does not identify it automatically.

The playbook configures the hostname, Wi-Fi client, and individual USB subnet.
The computer must be able to reach RAE over Wi-Fi. Check routing and client
isolation if the Wi-Fi SSH check fails. USB subnets in `inventory.yml` must not
overlap your Wi-Fi, LAN or VPN networks.

1. Configure networking for Alpha:

    ```console
    ansible-playbook 01-network-setup.yml --limit rae-alpha -e initial_host=192.168.197.55
    ```

1. Follow the Wi-Fi prompts and connect Alpha with USB-C when asked.

1. When the playbook finishes, reconnect USB-C or renew the computer's USB DHCP
   lease. Use automatic IPv4 (DHCP) on the computer's USB connection profile.
   Remove any old static `192.168.197.50/28` address from that profile.

1. Repeat for Beta:

    ```console
    ansible-playbook 01-network-setup.yml --limit rae-beta -e initial_host=192.168.197.55
    ```

To rerun network setup on a configured RAE, omit `initial_host`:

```console
ansible-playbook 01-network-setup.yml --limit rae-alpha
```
