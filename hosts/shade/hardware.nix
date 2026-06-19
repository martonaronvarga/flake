{
  pkgs,
  inputs,
  ...
}: let
  # Keep Mesa aligned with Hyprland's nixpkgs to avoid compositor/graphics ABI drift.
  pkgs-mesa = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  shadeHomeRollbackPrepare = pkgs.writeShellApplication {
    name = "shade-home-rollback-prepare";
    runtimeInputs = with pkgs; [
      btrfs-progs
      coreutils
      gnugrep
      util-linux
    ];
    text = ''
      set -euo pipefail

      if [[ ! -d /persist/home/usu ]]; then
        echo "/persist/home/usu is missing; verify persistence before creating home-blank" >&2
        exit 1
      fi

      uid="$(id -u usu 2>/dev/null || echo 1000)"
      gid="$(id -g usu 2>/dev/null || echo 100)"
      mnt="$(mktemp -d)"
      cleanup() {
        umount "$mnt" 2>/dev/null || true
        rmdir "$mnt"
      }
      trap cleanup EXIT

      mount -o subvol=/ /dev/mapper/cryptroot "$mnt"

      if [[ -e "$mnt/home-blank" ]] && ! btrfs subvolume show "$mnt/home-blank" >/dev/null 2>&1; then
        echo "$mnt/home-blank exists but is not a Btrfs subvolume" >&2
        exit 1
      fi

      if ! btrfs subvolume show "$mnt/home-blank" >/dev/null 2>&1; then
        btrfs subvolume create "$mnt/home-blank"
        install -d -m 0700 -o "$uid" -g "$gid" "$mnt/home-blank/usu"
      fi

      btrfs property set -ts "$mnt/home-blank" ro true
      echo "home-blank is ready at the top level of cryptroot"
    '';
  };
in {
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;

    graphics = {
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
  };

  services.fwupd.enable = true;

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

      systemd.services = {
        "btrfs-rollback" = {
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

        "btrfs-home-rollback" = {
          description = "Rollback home filesystem to pristine state when requested";
          before = ["sysroot-home.mount"];
          after = ["btrfs-rollback.service" "cryptsetup.target"];
          wantedBy = ["initrd.target"];
          serviceConfig = {
            Type = "oneshot";
            StandardOutput = "journal+console";
            StandardError = "journal+console";
          };
          script = ''
            set -euo pipefail

            if ! grep -qw shade.rollback_home=1 /proc/cmdline; then
              echo "Skipping /home rollback; add shade.rollback_home=1 to the kernel command line to run it"
              exit 0
            fi

            mkdir -p /mnt
            mount -o subvol=/ /dev/mapper/cryptroot /mnt

            cleanup() {
              umount /mnt 2>/dev/null || true
            }
            trap cleanup EXIT

            if ! btrfs subvolume show /mnt/home-blank >/dev/null 2>&1; then
              echo "Missing /mnt/home-blank; run shade-home-rollback-prepare first" >&2
              exit 1
            fi

            if [[ ! -d /mnt/persist/home/usu ]]; then
              echo "Missing /mnt/persist/home/usu; refusing to wipe /home" >&2
              exit 1
            fi

            if btrfs subvolume show /mnt/home >/dev/null 2>&1; then
              echo "Removing nested subvolumes under /mnt/home..."
              btrfs subvolume list -o /mnt/home |
                cut -f9 -d' ' |
                while read subvolume; do
                  echo "Deleting /$subvolume subvolume..."
                  btrfs subvolume delete "/mnt/$subvolume"
                done

              echo "Deleting /home subvolume..."
              btrfs subvolume delete /mnt/home
            elif [[ -e /mnt/home ]]; then
              echo "/mnt/home exists but is not a Btrfs subvolume" >&2
              exit 1
            fi

            echo "Restoring blank /home subvolume"
            btrfs subvolume snapshot /mnt/home-blank /mnt/home
            echo "/home rollback successful"
          '';
        };
      };
    };

    tmp.cleanOnBoot = true;
    consoleLogLevel = 3;
    kernelParams = ["quiet" "systemd.show_status=auto" "rd.udev.log_level=3"];
    resumeDevice = "/dev/mapper/cryptswap";

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;

    binfmt.emulatedSystems = ["aarch64-linux"];
  };

  environment.systemPackages = [
    pkgs.linuxPackages_latest.cpupower
    pkgs.sbctl
    shadeHomeRollbackPrepare
  ];
}
