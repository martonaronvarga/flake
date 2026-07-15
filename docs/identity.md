# Identity Material

Keep user identity, machine identity, and service identity separate. They rotate
for different reasons and have different blast radius.

## User Identity

User identity belongs to `usu` and follows the operator:

- SSH client key: `/persist/home/usu/.ssh/id_ed25519`
- Git signing key: configured in Home Manager Git settings
- GPG keyring: `/persist/home/usu/.gnupg`
- Forgejo HTTPS token: `pass show git/git.martonaronvarga.dev/usu`

These credentials are used for GitHub, Forgejo, SSH login, Git signing, and
operator decryption of age secrets.

## Mail Identity

`martonaronvarga.dev` addresses are public inbound aliases routed by Cloudflare
Email Routing to `martonaronvarga@gmail.com`. They are not independent hosted
mailboxes.

Use `martonaronvarga@gmail.com` as the authenticated SMTP sender unless Gmail
has a verified "send mail as" identity for a domain alias. Current service mail
therefore sends through Gmail as:

- Forgejo: `Forgejo <martonaronvarga@gmail.com>`
- Alertmanager: `Alertmanager <martonaronvarga@gmail.com>`
- Git patch email: `Marton A. Varga <martonaronvarga@gmail.com>`

Domain aliases remain appropriate as public contact, notification recipient,
Git commit identity, and account recovery addresses when inbound-only delivery
is sufficient.

Git commit signing uses SSH signatures. The local allowed signers file accepts
the routed domain aliases and Gmail address for the same `shade` signing key, so
commits can verify under any of those identities. The OpenPGP key is still
primarily used for mail and age-related workflows; add OpenPGP user IDs only
when you want to publish those aliases on the key itself.

## Machine Identity

Machine identity belongs to a host:

- `shade` age identity currently uses the `usu` SSH key.
- `dusk` age identity is `/persist/etc/agenix/dusk-age-key.txt`.
- Dusk SSH host key is persisted under `/persist/etc/ssh`.
- Dusk WireGuard private key is managed by agenix as
  `/run/agenix/dusk-wg-private-key`.

Machine identities should not be copied between hosts.

## Service Identity

Service secrets are decrypted by agenix at runtime:

- Forgejo mailer password: `/run/agenix/forgejo-mailer-password`
- Grafana admin password and secret key under `/run/agenix`
- Vaultwarden environment file: `/run/agenix/vaultwarden-env`
- Restic repository password: `/run/agenix/restic-shade-password`

Alertmanager currently reuses the Forgejo Gmail app password by generating a
runtime-only environment file under `/run/alertmanager`. Split this into a
dedicated app password later if separate rotation becomes useful.

## Recovery Material

Offline recovery should include:

- LUKS recovery keys;
- GPG recovery/export notes;
- Restic repository passwords;
- Vaultwarden emergency access or export;
- at least one non-domain recovery email.

Do not mark recovery complete until those materials are stored outside the
machines they recover.
