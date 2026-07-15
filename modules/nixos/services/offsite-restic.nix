{
  config,
  lib,
  ...
}: let
  cfg = config.local.backups.offsiteRestic;
in {
  options.local.backups.offsiteRestic = {
    enable = lib.mkEnableOption "off-site Restic backups over SSH";

    name = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}-offsite";
      description = "Name of the generated Restic backup job.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Local user that runs the backup.";
    };

    target = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "backup";
        description = "Remote SSH user for the off-site backup target.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "offsite-backup.invalid";
        description = "Remote SSH host for the off-site backup target.";
      };

      repositoryPath = lib.mkOption {
        type = lib.types.str;
        default = "/srv/restic/${config.networking.hostName}";
        description = "Remote path of the Restic repository.";
      };

      hostKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Pinned OpenSSH known_hosts line for the remote target.";
      };
    };

    identityFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SSH private key used for the off-site backup target.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Restic repository password file.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Paths included in the off-site backup.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Restic exclude patterns.";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
      ];
      description = "Restic retention options.";
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        OnCalendar = "05:30";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
      description = "Systemd timer configuration for the backup job.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = lib.optionals cfg.enable [
        {
          assertion = cfg.passwordFile != null;
          message = "local.backups.offsiteRestic.passwordFile must be set when off-site backups are enabled.";
        }
        {
          assertion = cfg.identityFile != null;
          message = "local.backups.offsiteRestic.identityFile must be set when off-site backups are enabled.";
        }
        {
          assertion = cfg.target.hostKey != null;
          message = "local.backups.offsiteRestic.target.hostKey must be set when off-site backups are enabled.";
        }
        {
          assertion = cfg.paths != [];
          message = "local.backups.offsiteRestic.paths must not be empty when off-site backups are enabled.";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      services.restic.backups.${cfg.name} = {
        inherit (cfg) user paths exclude pruneOpts passwordFile timerConfig;
        initialize = true;
        repository = "sftp:${cfg.target.user}@${cfg.target.host}:${cfg.target.repositoryPath}";
        checkOpts = [
          "--read-data-subset=1G"
        ];
        extraOptions = [
          "sftp.command='ssh ${cfg.target.user}@${cfg.target.host} -i ${cfg.identityFile} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/known_hosts.d/offsite-restic -s sftp'"
        ];
      };

      environment.etc."ssh/known_hosts.d/offsite-restic".text = ''
        ${cfg.target.hostKey}
      '';
    })
  ];
}
