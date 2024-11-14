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
        requires = [ "cryptroot.device" ];
        after = [ "cryptroot.target" ];
        wantedBy = [ "initrd.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
            mkdir -p /mnt
            mount -o subvol=/ /dev/mapper/cryptroot /mnt/root
            btrfs subvolume list -o /mnt/root | cut -f9 -d' ' |
            while read subvolume; do
                echo "Deleting /$subvolume subvolume"
                btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "Deleting /root subvolume" &&
            btrfs subvolume delete /mnt/root
            echo "Restoring blank /root subvolume"
            btrfs subvolume snapshot /mnt/root-blank /mnt/root
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
    options = [ "compress=zstd" "noatime" ];
  };

  

  environment.systemPackages =
    [ pkgs.linuxPackages_latest.cpupower pkgs.sbctl ];
}
