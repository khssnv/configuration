# ansible

1. Install roles and collections.

    ```console
    ansible-galaxy install -r requirements.yml
    ```

1. Export Proxmox VE API token secret for the dynamic inventory, see `.env.example`.

    ```console
    source .env
    ```

1. Configure ansible access on target hosts.

    ```console
    ansible-playbook -i inventories playbooks/01-bootstrap-ansible-access.yml
    ```

1. Bootstrap hosts with time sync services and base packages.

    ```console
    ansible-playbook -i inventories playbooks/02-bootstrap-base.yml
    ```

## Requirements

Playbooks rely on the Proxmox VE virtualized hosts tags.

| Purpose           | Tag prefix | Values                                               |
| ---               | ---        | ---                                                  |
| Bootstrap user    | bootstrap_ | bootstrap_root, bootstrap_ubuntu                     |
| Host management   | managed_   | managed_manual, managed_terraform                    |
| OS                | os_        | os_alpine, os_debian, os_proxmox_ve, os_truenas, os_ubuntu |
| Other             |            | community-script                                     |

## UPS on knas9

Set private `nut_monitor_password` (ASCII letters, digits, `_`, `-`) in
`inventories/host_vars/knas9.yml`.

```sh
ansible-playbook -i inventories playbooks/05-ups.yml
```

Check UPS status and charge on `knas9` after applying:

```sh
upsc ups@localhost ups.status
upsc ups@localhost battery.charge
```
