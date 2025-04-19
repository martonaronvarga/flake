{ pkgs, lib, ... }: {
  hardware.enableAllFirmware = true;
  boot = {

    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/etc/secureboot";
    # };

    bootspec.enable = true;

    initrd = {
      systemd.enable = true;
      luks.devices."cryptswap" = { 
        allowDiscards = true;
        device = "/dev/disk/by-partlabel/swap";
      };
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-partlabel/root";
        allowDiscards = true;
      };
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ "kvm-intel" ];

      systemd.services."btrfs-rollback" = {
        description = "Rollback root filesystem to pristine state";
        before = [ "sysroot.mount" ];
        after = [ "cryptroot.target" "dev-mapper-cryptroot.device" ];
        requires = [ "cryptroot.device" "cryptroot.target" "dev-mapper-cryptroot.device" ];
        wantedBy = [ "initrd.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
            set -euo pipefail
            mkdir -p /mnt
            mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /mnt
            if btrfs subvolume show /mnt/root-blank >/dev/null 2>&1; then
              btrfs subvolume delete /mnt/root
              btrfs subvolume snapshot /mnt/root-blank /mnt/root
              echo "Rollback successful"
            else
              echo "ERROR: root-blank snapshot missing!"
              exit 1
            fi
            umount /mnt
        '';
      };
    };

    tmp.cleanOnBoot = true;

    consoleLogLevel = 3;
    kernelParams = [ "quiet" "systemd.show_status=auto" "rd.udev.log_level=3" ];

    loader = {
      efi.canTouchEfiVariables = true;
     # systemd-boot.enable = lib.mkForce false;
      systemd-boot.enable = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;

  };

  fileSystems."/" = {
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  

  environment.systemPackages =
    [ pkgs.linuxPackages_latest.cpupower pkgs.sbctl ];
}
