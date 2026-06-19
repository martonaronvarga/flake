{pkgs, ...}: {
  hardware.enableRedistributableFirmware = true;

  boot = {
    initrd = {
      systemd.enable = true;
      supportedFilesystems = ["btrfs"];
      availableKernelModules = ["xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod"];
      systemd.services."btrfs-rollback" = {
        description = "Rollback root filesystem to pristine state";
        before = ["sysroot.mount"];
        wantedBy = ["initrd.target"];
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "journal+console";
          StandardError = "journal+console";
        };
        script = ''
          set -euo pipefail
          mkdir -p /mnt
          mount -o subvol=/ /dev/disk/by-label/gloam /mnt

          echo "Removing nested subvolumes under /mnt/root..."
          btrfs subvolume list -o /mnt/root |
            cut -f9 -d' ' |
            while read subvolume; do
              echo "Deleting /$subvolume subvolume..."
              btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "Deleting /root subvolume..." &&
            btrfs subvolume delete /mnt/root
          echo "Restoring blank /root subvolume"
          btrfs subvolume snapshot /mnt/root-blank /mnt/root
          echo "Rollback successful"

          umount /mnt
        '';
      };
    };

    loader = {
      efi.canTouchEfiVariables = false;
      systemd-boot.enable = true;
    };

    kernelParams = ["console=tty1" "console=ttyS0,115200"];
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
