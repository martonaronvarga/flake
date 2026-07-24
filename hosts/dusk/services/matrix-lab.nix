{
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) matrixLab network;
  backup = pkgs.writeShellApplication {
    name = "matrix-backup";
    runtimeInputs = with pkgs; [coreutils findutils postgresql util-linux];
    text = ''
      set -euo pipefail
      backup_dir=/persist/backups/matrix
      metric_dir=/var/lib/prometheus-node-exporter-textfiles
      stamp="$(date --utc +%Y%m%dT%H%M%SZ)"

      runuser -u postgres -- pg_dump --format=custom --file="$backup_dir/synapse-$stamp.pgdump" matrix-synapse
      runuser -u postgres -- pg_dump --format=custom --file="$backup_dir/slack-$stamp.pgdump" mautrix-slack
      find "$backup_dir" -type f -name '*.pgdump' -mtime +14 -delete

      install -d -m 0755 "$metric_dir"
      metric_tmp="$metric_dir/matrix-backup.prom.tmp"
      printf 'matrix_backup_last_success_seconds %s\n' "$(date +%s)" > "$metric_tmp"
      mv "$metric_tmp" "$metric_dir/matrix-backup.prom"
    '';
  };
in
  lib.mkIf matrixLab.enable {
    services.metascience-matrix = {
      enable = true;
      inherit (matrixLab) serverName publicHost adminMxid;
      listenAddress = network.dusk.wireguard.address;
      listenPort = network.dusk.ports.matrixLab;
      registration = false;
      federation = true;
      slack.enable = true;
    };

    networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
      network.dusk.ports.matrixLab
    ];

    systemd.services = {
      nginx = {
        after = ["wg-quick-${network.wireguard.interface}.service"];
        requires = ["wg-quick-${network.wireguard.interface}.service"];
      };
      matrix-backup = {
        description = "Back up the Matrix and Slack bridge databases";
        after = ["postgresql.service"];
        requires = ["postgresql.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${backup}/bin/matrix-backup";
          ReadWritePaths = [
            "/persist/backups/matrix"
            "/var/lib/prometheus-node-exporter-textfiles"
          ];
        };
      };
    };

    systemd.timers.matrix-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "03:45";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  }
