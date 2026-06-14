{
  pkgs,
  inputs,
  ...
}: let
  pkgs-mesa = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  hardware.graphics = {
    enable = true;
    package = pkgs-mesa.mesa;
    enable32Bit = true;
    package32 = pkgs-mesa.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      vpl-gpu-rt
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      libva
      intel-media-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [intel-vaapi-driver libvdpau-va-gl];
  };

  boot = {
    bootspec.enable = true;

    initrd = {
      systemd.enable = true;
      luks.devices."cryptswap" = {
        device = "/dev/disk/by-partlabel/swap";
        allowDiscards = true;
      };
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-partlabel/root";
        allowDiscards = true;
      };
      supportedFilesystems = ["btrfs"];
      availableKernelModules = ["xhci_pci" "nvme" "usb_storage" "sd_mod"];
      kernelModules = ["kvm-intel"];

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

    tmp.cleanOnBoot = true;
    consoleLogLevel = 3;
    kernelParams = ["quiet" "systemd.show_status=auto" "rd.udev.log_level=3"];
    resumeDevice = "/dev/mapper/cryptswap";

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
      # TODO migrate to lanzaboote
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  environment.systemPackages = [pkgs.linuxPackages_latest.cpupower pkgs.sbctl];
}
