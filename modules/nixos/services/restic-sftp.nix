{
  config,
  lib,
  pkgs,
  ...
}: let
  jobType = lib.types.submodule ({name, ...}: {
    options = {
      enable = lib.mkEnableOption "this Restic SFTP backup job";

      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "Local user that runs the backup.";
      };

      target = {
        user = lib.mkOption {
          type = lib.types.str;
          description = "Remote SSH user for the backup target.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          description = "Remote SSH host for the backup target.";
        };

        repositoryPath = lib.mkOption {
          type = lib.types.str;
          description = "Remote path of the Restic repository.";
        };

        hostKey = lib.mkOption {
          type = lib.types.str;
          description = "Pinned OpenSSH known_hosts line for the remote target.";
        };

        knownHostsName = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Name of the generated known_hosts.d file.";
        };
      };

      identityFile = lib.mkOption {
        type = lib.types.str;
        description = "SSH private key used for the backup target.";
      };

      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Restic repository password file.";
      };

      paths = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        description = "Paths included in the backup.";
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

      checkOpts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["--read-data-subset=1G"];
        description = "Restic check options.";
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
  });

  cfg = config.local.backups.resticSftp;
  enabledJobs = lib.filterAttrs (_: job: job.enable) cfg.jobs;
in {
  options.local.backups = {
    resticSftp.jobs = lib.mkOption {
      type = lib.types.attrsOf jobType;
      default = {};
      description = "Restic backup jobs that use SFTP repositories with pinned SSH host keys.";
    };

    offsiteRestic = {
      enable = lib.mkEnableOption "legacy off-site Restic backups over SSH";

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
  };

  config = lib.mkMerge [
    {
      assertions = lib.optionals config.local.backups.offsiteRestic.enable [
        {
          assertion = config.local.backups.offsiteRestic.passwordFile != null;
          message = "local.backups.offsiteRestic.passwordFile must be set when off-site backups are enabled.";
        }
        {
          assertion = config.local.backups.offsiteRestic.identityFile != null;
          message = "local.backups.offsiteRestic.identityFile must be set when off-site backups are enabled.";
        }
        {
          assertion = config.local.backups.offsiteRestic.target.hostKey != null;
          message = "local.backups.offsiteRestic.target.hostKey must be set when off-site backups are enabled.";
        }
        {
          assertion = config.local.backups.offsiteRestic.paths != [];
          message = "local.backups.offsiteRestic.paths must not be empty when off-site backups are enabled.";
        }
      ];
    }

    (lib.mkIf config.local.backups.offsiteRestic.enable {
      local.backups.resticSftp.jobs.${config.local.backups.offsiteRestic.name} = {
        enable = true;
        inherit
          (config.local.backups.offsiteRestic)
          user
          identityFile
          passwordFile
          paths
          exclude
          pruneOpts
          timerConfig
          ;
        target = {
          inherit (config.local.backups.offsiteRestic.target) user host repositoryPath hostKey;
          knownHostsName = "offsite-restic";
        };
      };
    })

    (lib.mkIf (enabledJobs != {}) {
      environment.systemPackages = [pkgs.restic];

      environment.etc = lib.mapAttrs' (_: job:
        lib.nameValuePair "ssh/known_hosts.d/${job.target.knownHostsName}" {
          text = ''
            ${job.target.hostKey}
          '';
        })
      enabledJobs;

      services.restic.backups =
        lib.mapAttrs (_: job: {
          inherit (job) user paths exclude pruneOpts passwordFile timerConfig checkOpts;
          initialize = true;
          repository = "sftp:${job.target.user}@${job.target.host}:${job.target.repositoryPath}";
          extraOptions = [
            "sftp.command='ssh ${job.target.user}@${job.target.host} -i ${job.identityFile} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/known_hosts.d/${job.target.knownHostsName} -s sftp'"
          ];
        })
        enabledJobs;
    })
  ];
}
