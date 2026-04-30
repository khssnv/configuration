# ansible

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
