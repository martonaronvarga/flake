{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.bootSecurity;
  secureBootStatus = pkgs.writeShellApplication {
    name = "secureboot-status";
    runtimeInputs = with pkgs; [
      sbctl
      systemd
    ];
    text = ''
      set -euo pipefail

      echo "== sbctl =="
      sbctl status || true

      echo
      echo "== bootctl =="
      bootctl status || true

      echo
      echo "== sbctl tracked files =="
      sbctl list-files || true
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
      gnugrep
      sbctl
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
        echo "Enter firmware setup and clear/reset Secure Boot keys into Setup Mode first." >&2
        echo "Do not enable local.bootSecurity.enableSecureBoot until enrollment succeeds." >&2
        exit 1
      fi

      sbctl enroll-keys --microsoft
      sbctl status
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
      ];
      environment.persistence."/persist".directories = [
        "/var/lib/sbctl"
      ];
    }

    (lib.mkIf cfg.enableSecureBoot {
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
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
