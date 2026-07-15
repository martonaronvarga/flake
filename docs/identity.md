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
