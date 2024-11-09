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

    };

    tmp.cleanOnBoot = true;

    consoleLogLevel = 3;
    kernelParams = [ "quiet" "systemd.show_status=auto" "rd.udev.log_level=3" ];

    loader = {
      efi.canTouchEfiVariables = true;
     # systemd-boot.enable = lib.mkForce false;
    };

    kernelPackages = pkgs.linuxPackages_latest;

  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;

  environment.systemPackages =
    [ pkgs.linuxPackages_latest.cpupower pkgs.sbctl ];
}
