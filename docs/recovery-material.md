# Recovery Material

This checklist is for offline material that cannot be reconstructed from Git.
Keep one printed copy or encrypted removable copy outside `shade` and `dusk`,
and keep a current Vaultwarden emergency path.

## Required Items

- LUKS passphrases for `shade` and `dusk`.
- LUKS recovery keys generated with `systemd-cryptenroll --recovery-key`.
- `shade` SSH key recovery note for age decryption:
  `/persist/home/usu/.ssh/id_ed25519`.
- `dusk` age identity recovery note:
  `/persist/etc/agenix/dusk-age-key.txt`.
- OpenPGP secret-key export and revocation certificate location.
- Restic repository passwords:
  `/run/agenix/restic-shade-password` at runtime, source in agenix.
- Vaultwarden admin/emergency process and latest export location.
- At least one recovery email that is not under `martonaronvarga.dev`.

## Verification Cadence

Once per quarter:

1. Boot with LUKS passphrase fallback available.
2. Confirm age decryption still works from `shade`.
3. Confirm Vaultwarden export or emergency access is current.
4. Run the Restic restore drill in `docs/backup-restore.md`.
5. Review Cloudflare Email Routing aliases and Gmail recovery settings.

Do not tick recovery-material TODOs until these items exist outside the
machines they recover.
