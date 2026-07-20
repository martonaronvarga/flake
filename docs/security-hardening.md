# Security hardening runbook

This repo enables the reversible parts of host hardening declaratively. Secure
Boot key enrollment and TPM-bound LUKS enrollment are still deliberate operator
steps because a mistake there can strand a machine at boot.

## Secure Boot

`shade` has Lanzaboote enabled and persists `/var/lib/sbctl`. `dusk` imports
the same support but Secure Boot remains deliberately deferred until its
separate recovery runbook has been completed at the local console.

For each host, from its local console:

```sh
secureboot-status
sudo secureboot-create-keys
```

If `secureboot-status` says `Setup Mode: Disabled`, reboot into firmware setup
and clear/reset Secure Boot keys so the machine enters Setup Mode. Do this only
when physically near the machine and with the LUKS passphrase available.

Once firmware Setup Mode is enabled:

```sh
sudo secureboot-enroll-keys
secureboot-status
```

Only after enrollment succeeds, set `local.bootSecurity.enableSecureBoot = true`
for that host and switch:

```sh
sudo nh os switch .#shade
sudo sbctl verify
bootctl status
```

Reboot once with firmware access available. Repeat on `dusk` only after `shade`
has completed a clean boot cycle.

Do not flip `enableSecureBoot` on both machines at once. If a machine fails to
boot, use the firmware menu to disable Secure Boot again, boot the previous
systemd-boot generation if needed, and revert the host option to `false`.

## TPM unlock

TPM unlock is additive. The existing passphrase must continue to work, and a
recovery key should be stored offline and in Vaultwarden before relying on TPM.

`shade`:

```sh
sudo systemd-cryptenroll /dev/disk/by-partlabel/root --recovery-key
sudo systemd-cryptenroll /dev/disk/by-partlabel/root --tpm2-device=auto --tpm2-pcrs=7
sudo systemd-cryptenroll /dev/disk/by-partlabel/swap --recovery-key
sudo systemd-cryptenroll /dev/disk/by-partlabel/swap --tpm2-device=auto --tpm2-pcrs=7
```

`dusk`:

```sh
sudo systemd-cryptenroll /dev/disk/by-partlabel/root --recovery-key
sudo dusk-enroll-tpm-unlock
```

After enrolling, reboot with the passphrase available and verify fallback still
works before leaving the machine unattended.

For an unattended `dusk` reboot, the critical command is
`sudo dusk-enroll-tpm-unlock`. It replaces any old TPM2 enrollment and binds the
root LUKS slot to the PCR policy declared in Nix. It still asks for the current
LUKS passphrase once, because that secret should never be piped through a remote
automation step.

## Checks

```sh
aa-status
auditctl -s
systemctl status smartd
systemctl list-timers '*scrub*' '*fstrim*'
ip route get 10.200.200.2
curl -I http://10.200.200.2:3000
```
