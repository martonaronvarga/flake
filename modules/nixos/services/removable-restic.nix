{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.backups.removable;
  quotedPaths = lib.concatMapStringsSep " " lib.escapeShellArg cfg.paths;
  backup = pkgs.writeShellApplication {
    name = "dusk-backup-external";
    runtimeInputs = with pkgs; [
      btrfs-progs
      coreutils
      cryptsetup
      findutils
      gnugrep
      mount
      restic
      rsync
      util-linux
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      device=${lib.escapeShellArg cfg.deviceById}
      mapper=/dev/mapper/${lib.escapeShellArg cfg.mapperName}
      actual_uuid="$(cryptsetup luksUUID "$device")"
      if [ "$actual_uuid" != ${lib.escapeShellArg cfg.luksUuid} ]; then
        echo "Refusing unexpected backup disk: LUKS UUID is $actual_uuid" >&2
        exit 1
      fi

      cleanup() {
        mountpoint -q ${lib.escapeShellArg cfg.mountPoint} && umount ${lib.escapeShellArg cfg.mountPoint} || true
        cryptsetup status ${lib.escapeShellArg cfg.mapperName} >/dev/null 2>&1 &&
          cryptsetup close ${lib.escapeShellArg cfg.mapperName} || true
      }
      trap cleanup EXIT

      cryptsetup open "$device" ${lib.escapeShellArg cfg.mapperName}
      install -d -m 0700 ${lib.escapeShellArg cfg.mountPoint}
      mount -o subvolid=5 "$mapper" ${lib.escapeShellArg cfg.mountPoint}

      dusk_repo=${lib.escapeShellArg "${cfg.mountPoint}/dusk-restic/repository"}
      shade_mirror=${lib.escapeShellArg "${cfg.mountPoint}/shade-mirror"}
      for path in "$dusk_repo" "$shade_mirror"; do
        if [ ! -d "$path" ]; then
          echo "Missing provisioned backup path: $path" >&2
          exit 1
        fi
      done

      export RESTIC_PASSWORD_FILE=${lib.escapeShellArg cfg.passwordFile}
      export RESTIC_REPOSITORY="$dusk_repo"
      restic snapshots >/dev/null 2>&1 || restic init
      restic backup ${quotedPaths}
      restic forget --prune --keep-daily 7 --keep-weekly 8 --keep-monthly 12
      restic check --read-data-subset=1G

      rsync -aHAX --delete --numeric-ids \
        ${lib.escapeShellArg "${cfg.shadeRepository}/"} "$shade_mirror/"
      RESTIC_PASSWORD_FILE=${lib.escapeShellArg cfg.shadePasswordFile} \
        RESTIC_REPOSITORY="$shade_mirror" restic check --read-data-subset=1G

      btrfs scrub start -B ${lib.escapeShellArg cfg.mountPoint}
      install -d -m 0755 /var/lib/prometheus-node-exporter-textfiles
      printf 'dusk_external_backup_last_success_seconds %s\n' "$(date +%s)" \
        > /var/lib/prometheus-node-exporter-textfiles/external-backup.prom.tmp
      mv /var/lib/prometheus-node-exporter-textfiles/external-backup.prom.tmp \
        /var/lib/prometheus-node-exporter-textfiles/external-backup.prom
    '';
  };
in {
  options.local.backups.removable = {
    enable = lib.mkEnableOption "manual encrypted removable Restic backup";
    deviceById = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    luksUuid = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    mapperName = lib.mkOption {
      type = lib.types.str;
      default = "dusk-backup";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/dusk-backup";
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    shadePasswordFile = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    shadeRepository = lib.mkOption {
      type = lib.types.str;
      default = "/persist/backups/restic/shade";
    };
    paths = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      default = [
        "/persist/backups/continuwuity"
        "/persist/backups/forgejo"
        "/persist/backups/vaultwarden"
        "/persist/etc/agenix"
        "/var/lib/forgejo"
        "/var/lib/continuwuity"
        "/var/lib/vaultwarden"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/dev/disk/by-id/" cfg.deviceById;
        message = "removable backup deviceById must use /dev/disk/by-id";
      }
      {
        assertion = cfg.luksUuid != "" && cfg.passwordFile != "" && cfg.shadePasswordFile != "";
        message = "removable backup requires LUKS UUID and both Restic password files";
      }
    ];
    environment.systemPackages = [backup];
  };
}
