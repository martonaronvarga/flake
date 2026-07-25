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

      inhibitSleep = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to block system sleep for the complete backup job.";
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
  };

  config = lib.mkIf (enabledJobs != {}) {
    environment.systemPackages = [pkgs.restic];

    environment.etc = lib.mapAttrs' (_: job:
      lib.nameValuePair "ssh/known_hosts.d/${job.target.knownHostsName}" {
        text = ''
          ${job.target.hostKey}
        '';
      })
    enabledJobs;

    services.restic.backups =
      lib.mapAttrs (_: job: let
        sftpCommand = "ssh ${job.target.user}@${job.target.host} -i ${job.identityFile} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/known_hosts.d/${job.target.knownHostsName} -s sftp";
        sftpOption = "sftp.command=${sftpCommand}";
      in {
        inherit (job) user paths exclude pruneOpts passwordFile timerConfig checkOpts;
        initialize = true;
        repository = "sftp:${job.target.user}@${job.target.host}:${job.target.repositoryPath}";
        extraOptions = [
          "sftp.command='${sftpCommand}'"
        ];
        backupPrepareCommand = ''
          ${pkgs.restic}/bin/restic -o ${lib.escapeShellArg sftpOption} unlock
        '';
      })
      enabledJobs;

    systemd.services = lib.mkMerge (lib.mapAttrsToList (name: job:
      lib.optionalAttrs job.inhibitSleep {
        "restic-backups-${name}" = {
          after = ["restic-backups-${name}-sleep-inhibitor.service"];
          requires = ["restic-backups-${name}-sleep-inhibitor.service"];
        };

        "restic-backups-${name}-sleep-inhibitor" = {
          description = "Sleep inhibitor for Restic backup ${name}";
          unitConfig.StopWhenUnneeded = true;
          serviceConfig = {
            Type = "simple";
            ExecStart = ''
              ${pkgs.systemd}/bin/systemd-inhibit \
                --what=sleep \
                --who=${lib.escapeShellArg "Restic backup ${name}"} \
                --why=${lib.escapeShellArg "Protecting an active Restic SFTP backup"} \
                --mode=block \
                ${pkgs.coreutils}/bin/sleep infinity
            '';
          };
        };
      })
    enabledJobs);
  };
}
