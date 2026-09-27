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
        after = ["cryptsetup.target"];
        requires = ["systemd-cryptsetup@cryptroot.service"];
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
      efi.canTouchEfiVariables = false;
      systemd-boot.enable = true;
    };

    kernelParams = ["console=tty1" "console=ttyS0,115200"];
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
