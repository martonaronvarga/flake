# Installing dusk

`dusk` started life as an old laptop running Arch. The useful trick was that it
already had Nix and SSH, so the install did not need a USB stick or a live ISO.
`shade` built the target system, `nixos-anywhere` kexec'd the laptop into a
temporary NixOS installer, and disko laid down the encrypted Btrfs layout.

The result is now a small home server with the same rollback and impermanence
shape as the rest of this flake: persistent state under `/persist`, an ephemeral
root restored from `root-blank`, and host secrets decrypted by agenix at boot.

## The shape of the host

The important files are:

- `hosts/dusk/disko.nix`: GPT, LUKS, Btrfs subvolumes, and the `root-blank`
  snapshot.
- `hosts/dusk/default.nix`: the `usu` account, agenix, SSH, Avahi, persistence,
  and local policy.
- `hosts/dusk/services/wireguard.nix`: the outbound tunnel to `gloam`.
- `parts/hosts.nix`: Colmena inventory and deployment settings.

`dusk` expects its age identity here:

```sh
/persist/etc/agenix/dusk-age-key.txt
```

That path matters. With impermanence, putting the key under plain `/etc/agenix`
is not enough; it may disappear or be hidden by the persistent bind mount before
agenix can decrypt the user password hash.

## Secret bootstrap

The host-local age key was generated on `shade` and intentionally kept out of
git:

```sh
age-keygen -o /tmp/dusk-age-key.txt
```

The public key was added to `secrets/secrets.nix` as the `dusk` recipient, and
the password hash secret was rekeyed from the secrets directory:

```sh
cd /persist/home/usu/flake/secrets
nix develop /persist/home/usu/flake -c agenix -r
```

For the install payload, the key was staged exactly where the installed system
would later need it:

```sh
rm -rf /tmp/dusk-extra-files
install -D -m 600 /tmp/dusk-age-key.txt \
  /tmp/dusk-extra-files/persist/etc/agenix/dusk-age-key.txt
```

The private key and `/tmp/dusk-extra-files` are machine-local bootstrap material,
not repository state.

## Preparing the Arch side

The Arch install only needed enough tooling to let `nixos-anywhere` take over.
`cpio` was required for the kexec initrd:

```sh
sudo pacman -Syu cpio
```

The temporary Arch user also needed non-interactive sudo:

```sh
echo 'martonaronvarga ALL=(ALL) NOPASSWD: ALL' |
  sudo tee /etc/sudoers.d/90-nixos-anywhere
sudo chmod 0440 /etc/sudoers.d/90-nixos-anywhere
```

Before running the install from `shade`, the useful sanity check was:

```sh
ssh martonaronvarga@<arch-ip> 'command -v cpio && sudo -n true'
```

The last human check before destruction was the disk name. The current disko
file formats `/dev/sda`, so `lsblk` needs to agree with that.

## The install

From `shade`:

```sh
cd /persist/home/usu/flake
nix run github:nix-community/nixos-anywhere -- \
  --flake /persist/home/usu/flake#dusk \
  --extra-files /tmp/dusk-extra-files \
  --target-host martonaronvarga@<arch-ip>
```

On this machine the kexec installer came up, but Wi-Fi did not immediately come
back. The way forward was not to restart the whole install; it was to restore
networking on the installer console and resume after the kexec phase:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --phases disko,install,reboot \
  --flake /persist/home/usu/flake#dusk \
  --extra-files /tmp/dusk-extra-files \
  --target-host root@<installer-ip>
```

That second invocation did the destructive part: disko, install, and reboot.

## Recovery lesson

The one real snag was the agenix key location. A key copied to `/etc/agenix`
does not satisfy a config that reads `/persist/etc/agenix/dusk-age-key.txt`.
The symptom was simple: the system booted to `dusk login:`, but the declared
`usu` password did not work because agenix could not decrypt the password hash.

Without a USB stick, the local recovery path was the systemd debug shell:

```text
systemd.debug_shell=1
```

Then on TTY 9:

```sh
export PATH=/run/current-system/sw/bin:/usr/bin:/bin:/sbin:/run/wrappers/bin
mkdir -p /persist/etc/agenix
chmod 700 /persist/etc/agenix
cat > /persist/etc/agenix/dusk-age-key.txt
chmod 600 /persist/etc/agenix/dusk-age-key.txt
chown root:root /persist/etc/agenix/dusk-age-key.txt
sync
reboot
```

After the key was in `/persist`, agenix could decrypt the hash and `usu` login
worked normally.

## After first boot

The checks that mattered:

```sh
ssh usu@dusk.local
systemctl status agenix
systemctl status sshd
systemctl status wg-quick-wg0
sudo wg show wg0
```

The WireGuard public key was then read from `dusk` and copied into the `gloam`
peer configuration:

```sh
sudo wg pubkey < /persist/etc/wireguard/wg0.key
```
