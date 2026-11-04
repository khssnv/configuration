# Security

Scope: `client -> gateway (2.vpsza500) -> WireGuard -> ingress -> homelab service`.
Protected assets: service data, user identities, credentials, TLS keys, and
administrative access. These are requirements, not verified deployment guarantees.

Assume only the named component is compromised. WireGuard authenticates peers
and encrypts the tunnel; peer identity and network location grant no application
or administrative privileges. TLS endpoints are trusted with their plaintext.
Services must authenticate users and protect credentials and sessions.

## Gateway compromise

The gateway forwards TCP 80/443 without terminating TLS. Root compromise exposes
its files, processes, WireGuard key, relay token, and traffic. Accepted impacts
are denial of service, capture of encrypted traffic and metadata, and reading or
modifying plaintext traffic. Plaintext must not carry credentials or operations
requiring transport protection.

Gateway compromise must not grant ingress administration, unauthorized homelab
access, user impersonation, decryption of protected traffic, or unauthorized
changes to service data. Therefore:

- Keep homelab TLS keys, ACME account keys and backups, user credentials, and
  ingress/backend administrative credentials off the gateway.
- Expose only intended public ingress listeners to the gateway; separate
  administration and restrict backend connections and credentials per service.
- Backends enforce authorization. Trust in identities asserted by ingress must
  be explicit; client identity and forwarding headers require authenticated
  provenance.

## Certificate issuance

Clients must authenticate the intended TLS endpoint. A compromised gateway can
answer HTTP-01 or TLS-ALPN-01 challenges, so challenge control alone is
insufficient protection against unauthorized certificate issuance.

Each independent TLS endpoint manages its own certificates and ACME account.
Domain-specific CAA restricts issuance to that account and the selected challenge
method. The account key and DNS management access remain outside the gateway.
Restricting only the CA or only HTTP-01 does not establish this boundary.

Preserving the ACME account avoids CAA changes during recovery and unnecessary
[account registrations](https://letsencrypt.org/docs/rate-limits/#account-registration-limits).
See [DNS setup and verification](DNS.md). `enableACME = true` alone does not
establish independence from the gateway.

## Ingress compromise

Root compromise exposes TLS keys, credentials, sessions, and plaintext handled
by ingress. An attacker can modify responses and impersonate services whose
keys ingress holds. Trust in identities asserted by ingress is lost.

Containment still requires backend authorization and no general administrative
access from ingress to the homelab. Services terminating their own TLS manage
their keys and accounts independently.

## Syncthing relay

The relay token must grant neither access to synchronized data nor a trusted
device identity. Verify relay protections separately from HTTP ingress.

See [OWASP threat modeling](https://owasp.github.io/www-project-threat-modeling/)
for terminology and [Let's Encrypt challenges](https://letsencrypt.org/docs/challenge-types/)
for validation methods.
