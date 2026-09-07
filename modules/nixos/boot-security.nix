{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.bootSecurity;
  luksDevices = map (name: config.boot.initrd.luks.devices.${name}.device) cfg.luksDeviceNames;
  quotedLuksDevices = lib.concatMapStringsSep " " lib.escapeShellArg luksDevices;
  secureBootStatus = pkgs.writeShellApplication {
    name = "secureboot-status";
    runtimeInputs = with pkgs; [
      sbctl
      sudo
      systemd
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      echo "== sbctl =="
      sbctl status || true

      echo
      echo "== bootctl =="
      bootctl status || true

      echo
      echo "== sbctl tracked files =="
      sbctl list-files || true

      devices=(${quotedLuksDevices})
      for device in "''${devices[@]}"; do
        echo
        echo "== LUKS enrollments: $device =="
        systemd-cryptenroll "$device" || true
      done
    '';
  };
  secureBootCreateKeys = pkgs.writeShellApplication {
    name = "secureboot-create-keys";
    runtimeInputs = with pkgs; [
      coreutils
      sbctl
      sudo
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      if [ -d ${lib.escapeShellArg cfg.pkiBundle}/keys ]; then
        echo "sbctl keys already exist under ${cfg.pkiBundle}/keys"
        sbctl status || true
        exit 0
      fi

      install -d -m 0755 ${lib.escapeShellArg cfg.pkiBundle}
      sbctl create-keys
      sbctl status || true
    '';
  };
  secureBootEnrollKeys = pkgs.writeShellApplication {
    name = "secureboot-enroll-keys";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      sbctl
      sbsigntool
      sudo
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      if [ ! -d ${lib.escapeShellArg cfg.pkiBundle}/keys ]; then
        echo "No sbctl keys found under ${cfg.pkiBundle}/keys." >&2
        echo "Run: sudo secureboot-create-keys" >&2
        exit 1
      fi

      status="$(sbctl status || true)"
      printf '%s\n' "$status"

      if ! printf '%s\n' "$status" | grep -Eq 'Setup Mode:[[:space:]]+.*Enabled'; then
        echo >&2
        echo "Firmware Setup Mode is not enabled, so sbctl cannot safely enroll owner keys." >&2
        echo "Deploy Lanzaboote and verify its signed boot artifacts first." >&2
        echo "Then enter firmware setup and use Reset to Setup Mode (not Clear All Secure Boot Keys)." >&2
        exit 1
      fi

      required_artifacts=(
        /boot/EFI/systemd/systemd-bootx64.efi
        /boot/EFI/BOOT/BOOTX64.EFI
      )
      for artifact in "''${required_artifacts[@]}"; do
        if [ ! -f "$artifact" ]; then
          echo "Required boot artifact is missing: $artifact" >&2
          exit 1
        fi
        sbverify --list "$artifact" >/dev/null
      done

      shopt -s nullglob
      ukis=(/boot/EFI/Linux/*.efi)
      if [ "''${#ukis[@]}" -eq 0 ]; then
        echo "No Lanzaboote UKIs found under /boot/EFI/Linux." >&2
        exit 1
      fi
      for uki in "''${ukis[@]}"; do
        sbverify --list "$uki" >/dev/null
      done

      sbctl enroll-keys --microsoft
      sbctl status
    '';
  };
  secureBootEnrollTpmUnlock = pkgs.writeShellApplication {
    name = "secureboot-enroll-tpm-unlock";
    runtimeInputs = with pkgs; [
      coreutils
      sudo
      systemd
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      if [ ! -e /dev/tpmrm0 ] && [ ! -e /dev/tpm0 ]; then
        echo "No TPM device found at /dev/tpmrm0 or /dev/tpm0." >&2
        exit 1
      fi

      devices=(${quotedLuksDevices})
      if [ "''${#devices[@]}" -eq 0 ]; then
        echo "No LUKS devices are configured for TPM2 unlock." >&2
        exit 1
      fi

      for device in "''${devices[@]}"; do
        if [ ! -b "$device" ]; then
          echo "LUKS device is not available: $device" >&2
          exit 1
        fi
      done

      for device in "''${devices[@]}"; do
        echo "Enrolling TPM2 unlock for $device using PCR policy ${cfg.tpmPcrs}."
        echo "You will be asked for an existing LUKS passphrase."
        systemd-cryptenroll "$device" \
          --wipe-slot=tpm2 \
          --tpm2-device=auto \
          --tpm2-pcrs=${lib.escapeShellArg cfg.tpmPcrs}

        echo
        echo "Current LUKS enrollments for $device:"
        systemd-cryptenroll "$device"
      done
    '';
  };
in {
  options.local.bootSecurity = {
    enableSecureBoot = lib.mkEnableOption "Lanzaboote Secure Boot support";
    enableTpmUnlock = lib.mkEnableOption "TPM2-assisted LUKS unlock";
    luksDeviceNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Names under boot.initrd.luks.devices that should try TPM2 unlock before passphrase fallback.";
    };
    tpmPcrs = lib.mkOption {
      type = lib.types.str;
      default = "7";
      description = "TPM2 PCR policy used by both crypttab and systemd-cryptenroll.";
    };
    pkiBundle = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sbctl";
      description = "Persistent sbctl PKI bundle used by Lanzaboote.";
    };
  };

  config = lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.sbctl
        secureBootStatus
        secureBootCreateKeys
        secureBootEnrollKeys
        secureBootEnrollTpmUnlock
      ];
      environment.persistence."/persist".directories = [
        cfg.pkiBundle
      ];
    }

    (lib.mkIf cfg.enableSecureBoot {
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        configurationLimit = 8;
        inherit (cfg) pkiBundle;
      };
    })

    (lib.mkIf cfg.enableTpmUnlock {
      boot.initrd.luks.devices = lib.genAttrs cfg.luksDeviceNames (_name: {
        crypttabExtraOpts = [
          "tpm2-device=auto"
          "tpm2-pcrs=${cfg.tpmPcrs}"
          "tpm2-measure-pcr=yes"
        ];
      });
    })
  ];
}
