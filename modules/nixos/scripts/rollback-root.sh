set -euo pipefail
mkdir -p /mnt
mount -o subvol=/ /dev/mapper/cryptroot /mnt
trap 'umount /mnt' EXIT

# Validate the recovery snapshot before touching the current root.
btrfs subvolume show /mnt/root-blank >/dev/null
if [[ -e /mnt/root ]]; then
  btrfs subvolume show /mnt/root >/dev/null
  btrfs subvolume delete --recursive /mnt/root
fi
btrfs subvolume snapshot /mnt/root-blank /mnt/root
echo "Root rollback successful"
