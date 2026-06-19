{pkgs, ...}: {
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
  };

  services.fwupd.enable = true;

  boot = {
    initrd = {
      systemd.enable = true;
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-partlabel/root";
        allowDiscards = true;
      };
      supportedFilesystems = ["btrfs"];
      availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod"];
      kernelModules = [];

      systemd.services."btrfs-rollback" = {
        description = "Rollback root filesystem to pristine state";
        before = ["sysroot.mount"];
        after = ["cryptsetup.target"];
        wantedBy = ["initrd.target"];
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "journal+console";
          StandardError = "journal+console";
        };
        script = ''
          set -euo pipefail
          mkdir -p /mnt
          mount -o subvol=/ /dev/mapper/cryptroot /mnt

          # Delete all nested subvolumes under /mnt/root
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
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    tmp.cleanOnBoot = true;
    consoleLogLevel = 3;
    kernelParams = ["quiet" "console=tty1"];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    smartmontools
  ];
}
