{
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) domain network;
  backupRoot = "/persist/backups/continuwuity";
  databaseBackup = "${backupRoot}/database";
  weeklyBackup = "${backupRoot}/weekly";
  metricsDir = "/var/lib/prometheus-node-exporter-textfiles";
  maintenance = pkgs.writeShellApplication {
    name = "continuwuity-maintenance";
    runtimeInputs = with pkgs; [coreutils findutils gnugrep systemd];
    text = ''
      set -euo pipefail

      started="$(date +%s)"
      systemctl kill --signal=SIGUSR2 continuwuity.service

      deadline=$((started + 600))
      while ! find ${databaseBackup} -type f -newermt "@$started" -print -quit | grep -q .; do
        if [ "$(date +%s)" -ge "$deadline" ]; then
          echo "Continuwuity did not produce a fresh database backup within 10 minutes." >&2
          exit 1
        fi
        sleep 5
      done

      install -d -m 0755 ${metricsDir}
      metric_tmp=${metricsDir}/continuwuity-maintenance.prom.tmp
      printf 'continuwuity_backup_last_success_seconds %s\n' "$(date +%s)" > "$metric_tmp"
      mv "$metric_tmp" ${metricsDir}/continuwuity-maintenance.prom
    '';
  };
  weeklyArchive = pkgs.writeShellApplication {
    name = "continuwuity-weekly-archive";
    runtimeInputs = with pkgs; [coreutils findutils gnutar zstd];
    text = ''
      set -euo pipefail

      stamp="$(date --utc +%Y%m%dT%H%M%SZ)"
      archive=${weeklyBackup}/continuwuity-"$stamp".tar.zst
      tar --zstd -C / -cpf "$archive" \
        persist/backups/continuwuity/database \
        var/lib/continuwuity/media

      find ${weeklyBackup} -maxdepth 1 -type f -name 'continuwuity-*.tar.zst' \
        -printf '%T@ %p\n' | sort -nr | tail -n +5 | cut -d' ' -f2- | xargs -r rm --

      metric_tmp=${metricsDir}/continuwuity-weekly.prom.tmp
      printf 'continuwuity_weekly_archive_last_success_seconds %s\n' "$(date +%s)" > "$metric_tmp"
      printf 'continuwuity_weekly_archive_count %s\n' \
        "$(find ${weeklyBackup} -maxdepth 1 -type f -name 'continuwuity-*.tar.zst' | wc -l)" \
        >> "$metric_tmp"
      mv "$metric_tmp" ${metricsDir}/continuwuity-weekly.prom
    '';
  };
in {
  services.matrix-continuwuity = {
    enable = true;
    settings.global = {
      server_name = domain;
      address = [network.dusk.wireguard.address];
      port = [network.dusk.ports.matrix];
      max_request_size = 50 * 1024 * 1024;
      new_user_displayname_suffix = "";

      allow_registration = false;
      allow_guest_registration = false;
      allow_encryption = true;
      allow_federation = true;
      trusted_servers = ["matrix.org"];
      allow_public_room_directory_over_federation = false;
      lockdown_public_room_directory = true;
      allow_web_indexing = false;
      allow_device_name_federation = false;
      allow_inbound_profile_lookup_federation_requests = true;
      allow_local_presence = true;
      allow_incoming_presence = true;
      allow_outgoing_presence = false;

      url_preview_domain_contains_allowlist = [];
      url_preview_domain_explicit_allowlist = [];
      url_preview_url_contains_allowlist = [];

      allow_announcements_check = false;
      log = "warn";
      admins_list = ["@usu:${domain}"];
      database_backup_path = databaseBackup;
      database_backups_to_keep = 7;
      admin_signal_execute = [
        "server backup-database"
        "media delete-past-remote-media -b 90d"
      ];
      well_known = {
        client = "https://matrix.${domain}";
        server = "matrix.${domain}:443";
        support_role = "m.role.admin";
        support_mxid = "@usu:${domain}";
      };
    };
  };

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.dusk.ports.matrix
  ];

  systemd.services = {
    continuwuity = {
      after = ["wg-quick-${network.wireguard.interface}.service"];
      requires = ["wg-quick-${network.wireguard.interface}.service"];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        ReadWritePaths = [databaseBackup];
      };
    };
    continuwuity-maintenance = {
      description = "Create a Continuwuity backup and prune old remote media";
      after = ["continuwuity.service"];
      requires = ["continuwuity.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${maintenance}/bin/continuwuity-maintenance";
      };
    };
    continuwuity-weekly-archive = {
      description = "Archive a Continuwuity database backup and local media";
      after = ["continuwuity-maintenance.service"];
      requires = ["continuwuity-maintenance.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${weeklyArchive}/bin/continuwuity-weekly-archive";
      };
    };
  };

  systemd.timers = {
    continuwuity-maintenance = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "03:45";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    continuwuity-weekly-archive = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Sun 04:30";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  };
}
