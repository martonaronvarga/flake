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
        script = builtins.readFile ../../modules/nixos/scripts/rollback-root.sh;
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
