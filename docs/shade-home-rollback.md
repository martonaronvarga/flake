# Shade Home Rollback Dry Run

This checklist keeps `/home` rollback opt-in until persistence coverage has been verified. The boot-time rollback service only runs when `shade.rollback_home=1` is present on the kernel command line.

## Before Creating `home-blank`

1. Enumerate persisted Home Manager paths:

   ```sh
   nix eval .#nixosConfigurations.shade.config.home-manager.users.usu.home.persistence."/persist".directories --json | jq .
   nix eval .#nixosConfigurations.shade.config.home-manager.users.usu.home.persistence."/persist".files --json | jq .
   ```

2. Enumerate system persistence for `/persist`:

   ```sh
   nix eval .#nixosConfigurations.shade.config.environment.persistence."/persist".directories --json | jq .
   nix eval .#nixosConfigurations.shade.config.environment.persistence."/persist".files --json | jq .
   ```

3. Verify the user persistence root exists and contains the expected state:

   ```sh
   test -d /persist/home/usu
   find /persist/home/usu -maxdepth 3 -mindepth 1 | sort | less
   ```

4. Back up the current `/home` subvolume before the first destructive test:

   ```sh
   sudo mkdir -p /.snapshots/manual
   sudo btrfs subvolume snapshot -r /home "/.snapshots/manual/home-before-rollback-$(date +%Y%m%d-%H%M%S)"
   ```

## Create Or Refresh `home-blank`

Run the prepared helper after rebuilding this configuration:

```sh
sudo shade-home-rollback-prepare
sudo btrfs subvolume show /home-blank || true
```

The helper mounts the Btrfs top level, verifies `/persist/home/usu`, creates `home-blank` if missing, creates an empty `usu` home with restrictive permissions, and marks the blank subvolume read-only.

## Manual Rescue-Shell Test

Before enabling boot-time rollback for daily use, boot a rescue environment, unlock `cryptroot`, and run the same destructive sequence manually:

```sh
cryptsetup open /dev/disk/by-partlabel/root cryptroot
mount -o subvol=/ /dev/mapper/cryptroot /mnt

btrfs subvolume show /mnt/home-blank
test -d /mnt/persist/home/usu

btrfs subvolume list -o /mnt/home | cut -f9 -d' ' | while read subvolume; do
  btrfs subvolume delete "/mnt/$subvolume"
done
btrfs subvolume delete /mnt/home
btrfs subvolume snapshot /mnt/home-blank /mnt/home

umount /mnt
cryptsetup close cryptroot
```

Boot normally and verify Home Manager/persistence repopulates the expected symlinks and bind mounts.

## One-Shot Boot Test

Only after the manual test passes, add this kernel parameter once from the bootloader editor:

```text
shade.rollback_home=1
```

The initrd service refuses to run unless `home-blank` exists and `/persist/home/usu` is present. Remove the parameter after the test boot; keeping it set makes `/home` ephemeral on every boot.
