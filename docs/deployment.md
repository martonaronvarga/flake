# Deployment

Use this checklist before changing `shade` or `dusk`. Keep generated files and
local audit notes out of commits unless they are intentionally promoted.

## Preflight

```sh
git status --short
alejandra --check .
statix check .
deadnix --fail .
nix flake check --no-write-lock-file
nix build .#shade
nix build .#dusk
```

If a build failure is caused by an unrelated upstream package, record the exact
derivation and do not deploy unless the target host build you need is known to
evaluate and build.

## Deploy Dusk

```sh
nix develop -c colmena apply --on dusk
ssh dusk 'systemctl --failed --no-pager'
ssh dusk 'systemctl is-active nginx forgejo vaultwarden grafana prometheus alertmanager'
```

Check the WireGuard path after network changes:

```sh
ssh gloam 'sudo wg show wg0'
ssh dusk 'sudo wg show wg0'
ssh dusk-wg hostname
```

## Switch Shade

From `shade`:

```sh
sudo nixos-rebuild switch --flake .#shade
systemctl --failed --no-pager
systemctl --user --failed --no-pager
```

## Rollback

List generations:

```sh
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

Temporarily boot the previous generation from the systemd-boot menu, or switch
back explicitly:

```sh
sudo /nix/var/nix/profiles/system-<generation>-link/bin/switch-to-configuration switch
```

For service-specific failures, inspect the unit before rolling back unrelated
host state:

```sh
journalctl -u forgejo -n 200 --no-pager
journalctl -u vaultwarden -n 200 --no-pager
journalctl -u prometheus -u alertmanager -n 200 --no-pager
```
