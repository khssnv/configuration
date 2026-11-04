# Configure DNS and CAA

DNS is managed manually; keep DNS management access off the gateway.
For each service, identify its TLS endpoint and obtain the gateway's public IP
addresses. Use the ingress ACME account only when ingress terminates that TLS.

## Publish or restore a service

1. Restore the endpoint's ACME account from a protected backup, or register a
   production Let's Encrypt account using its ACME client. Obtain the account
   URI from the registration response or a non-secret account record; use its
   final numeric component as `<ACCOUNT_ID>` below.
1. Point the service name directly to the gateway with A/AAAA records.
   `ingress.khassanov.xyz` is a separate name for ingress itself.
1. Set CAA at the service name. For ingress's non-wildcard HTTP-01 issuance:

   ```dns
   myservice.khassanov.xyz. CAA 0 issue "letsencrypt.org; accounturi=https://acme-v02.api.letsencrypt.org/acme/acct/<ACCOUNT_ID>; validationmethods=http-01"
   ```

   For another TLS endpoint, use its account and configured challenge method.
   Remove other `issue` records that permit unintended issuance.
1. If an explicit wildcard policy is needed, set one of these `issuewild` values
   at the same name, removing other permissive `issuewild` records:

   - Prohibit wildcard certificates: `";"`.
   - Allow them for the selected account:
     `"letsencrypt.org; accounturi=https://acme-v02.api.letsencrypt.org/acme/acct/<ACCOUNT_ID>; validationmethods=dns-01"`.

   For wildcard issuance, configure DNS-01 and manually add the client's requested
   TXT records at `_acme-challenge.myservice.khassanov.xyz`. Without `issuewild`,
   the `issue` restriction also applies to wildcards.

See [Let's Encrypt CAA](https://letsencrypt.org/docs/caa/) for record semantics.

## Verify

1. Query A, AAAA, and CAA with `dig` against authoritative and public recursive
   nameservers. Expect the gateway addresses and selected CAA policy, with no
   unintended issuance permissions. Wait for previous DNS and CA caches to expire.
1. Request a certificate through the intended endpoint. Confirm successful
   issuance and that the expected service loads over valid HTTPS from outside
   the homelab.
1. On a separate test name with equivalent CAA and a working challenge path,
   attempt issuance using a different production account. Expect an explicit CAA
   refusal; a timeout or challenge failure does not verify the restriction.

## Preserve account state

On ingress, preserve all of `/var/lib/acme`, including `.lego/accounts` and
hidden files. Certificates alone do not preserve the ACME account. Keep its
non-secret URI with the DNS records. Reuse the account after recovery; if it
changes, update `accounturi` and repeat verification.

The commands below are for the operator to run. They transfer private account
and certificate keys. Run them only from a trusted administrative machine,
over verified SSH directly to ingress, never from the public gateway. Do not
print or commit the archive or its contents.

### Save

Back up after account registration and before replacing the VM or its disk.
Use `age` on the administrative machine with an existing backup recipient.
Keep the corresponding decryption identity separately from ingress and the
gateway. See the [age documentation](https://github.com/FiloSottile/age).

1. Set the VM address, the public backup recipient, and a new archive path on
   the administrative machine:

   ```sh
   INGRESS_IP="<vm-ip>"
   BACKUP_RECIPIENT="age1..."
   ACME_BACKUP="/path/to/protected-backups/ingress-acme.tar.gz.age"
   ```

1. Pause renewal to avoid copying state while it changes. These unit names are
   for the current test page; include the renewal timers and order services of
   any additional certificates. Do not rebuild or reboot during the backup.

   ```sh
   ssh root@"$INGRESS_IP" 'systemctl stop acme-renew-ingress.khassanov.xyz.timer'
   ssh root@"$INGRESS_IP" 'systemctl stop acme-order-renew-ingress.khassanov.xyz.service'
   ```

1. In Bash or Zsh, stream the archive directly into encryption. No plaintext
   archive is written to disk:

   ```sh
   set -o pipefail
   umask 077
   ssh root@"$INGRESS_IP" \
     'tar --acls --xattrs --numeric-owner -C /var/lib -czf - acme' \
     | age --recipient "$BACKUP_RECIPIENT" --output "$ACME_BACKUP"
   ```

   Check the pipeline exit status. A failed command can leave an incomplete
   archive; do not treat it as a backup. Keep a protected copy outside the VM
   and test recovery before deleting the original state. Terraform state does
   not back up the guest filesystem.

1. Resume renewal, including if the backup failed and the VM remains in use:

   ```sh
   ssh root@"$INGRESS_IP" 'systemctl start acme-renew-ingress.khassanov.xyz.timer'
   ```

### Restore

1. Bootstrap the replacement VM and verify its SSH host key through a trusted
   administrative channel. Restore before the first deployment of the ACME
   configuration so that it cannot register a replacement account. For recovery
   on an already configured ingress, pause renewal as above and stop Nginx
   first. Do not merge a backup into unrelated or newly generated ACME state;
   preserve that state separately and restore into an absent `/var/lib/acme`.

1. On the administrative machine, set `INGRESS_IP`, `ACME_BACKUP`, and the path
   to the existing backup identity. Decrypt only the trusted backup and stream
   it directly to ingress:

   ```sh
   BACKUP_IDENTITY="/path/to/backup-age-identity"
   set -o pipefail
   age --decrypt --identity "$BACKUP_IDENTITY" "$ACME_BACKUP" \
     | ssh root@"$INGRESS_IP" \
         'tar --acls --xattrs --numeric-owner -C /var/lib -xzf -'
   ```

   Check the pipeline exit status before proceeding. If restoration fails,
   keep issuance stopped and recover from a valid backup.

1. Deploy the same ingress configuration, retaining the ACME server, email, and
   key type used when the account was created. NixOS uses those settings to
   select the account state directory; changing them can select another account.
   Its ACME setup service restores ownership and permissions for the account
   and certificate directories. On an already configured host, run
   `systemctl restart acme-setup.service` as root before resuming issuance.

1. Confirm the restored account URI matches DNS `accounturi`. Keep CAA in place;
   do not temporarily relax it to make issuance succeed. As root on ingress,
   start Nginx so that HTTP-01 is reachable, then start the test page's order
   service and renewal timer:

   ```sh
   systemctl start nginx.service
   systemctl start acme-order-renew-ingress.khassanov.xyz.service
   systemctl start acme-renew-ingress.khassanov.xyz.timer
   ```

1. Repeat the [verification](#verify), including valid external HTTPS and an
   explicit CAA refusal for a different account on a separate test name.
