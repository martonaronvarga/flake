{
  config,
  infraNetwork,
  lib,
  pkgs,
  ...
}: let
  alertmanagerEnv = "/run/alertmanager/smtp.env";
  dashboard = {
    uid,
    title,
    panels,
  }:
    pkgs.writeText "${uid}.json" (builtins.toJSON {
      inherit uid title panels;
      schemaVersion = 41;
      version = 1;
      refresh = "1m";
      time = {
        from = "now-6h";
        to = "now";
      };
      tags = ["dusk" "provisioned"];
      timezone = "browser";
    });
  statPanel = {
    id,
    title,
    expr,
    x,
    y,
    w ? 6,
    h ? 4,
    unit ? "short",
  }: {
    inherit id title;
    type = "stat";
    gridPos = {inherit h w x y;};
    targets = [
      {
        refId = "A";
        inherit expr;
      }
    ];
    fieldConfig.defaults = {
      inherit unit;
      color.mode = "thresholds";
      thresholds = {
        mode = "absolute";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "red";
            value = 1;
          }
        ];
      };
    };
    options.reduceOptions.calcs = ["lastNotNull"];
  };
  timeSeriesPanel = {
    id,
    title,
    expr,
    x,
    y,
    w ? 12,
    h ? 8,
    unit ? "short",
  }: {
    inherit id title;
    type = "timeseries";
    gridPos = {inherit h w x y;};
    targets = [
      {
        refId = "A";
        inherit expr;
        legendFormat = "{{instance}}";
      }
    ];
    fieldConfig.defaults.unit = unit;
  };
  dashboards = pkgs.runCommand "dusk-grafana-dashboards" {} ''
    install -d "$out"
    cp ${dashboard {
      uid = "fleet-overview";
      title = "Fleet overview";
      panels = [
        (statPanel {
          id = 1;
          title = "Targets up";
          expr = "sum(up)";
          x = 0;
          y = 0;
        })
        (statPanel {
          id = 2;
          title = "Memory available";
          expr = "node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes";
          x = 6;
          y = 0;
          unit = "percentunit";
        })
        (timeSeriesPanel {
          id = 3;
          title = "CPU usage";
          expr = "1 - avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))";
          x = 0;
          y = 4;
          unit = "percentunit";
        })
        (timeSeriesPanel {
          id = 4;
          title = "Load average";
          expr = "node_load1";
          x = 12;
          y = 4;
        })
      ];
    }} "$out/fleet-overview.json"
    cp ${dashboard {
      uid = "storage-backup";
      title = "Storage and backup";
      panels = [
        (statPanel {
          id = 1;
          title = "Dusk /persist free";
          expr = "node_filesystem_avail_bytes{instance=\"dusk\", mountpoint=\"/persist\", fstype!~\"tmpfs|overlay\"}";
          x = 0;
          y = 0;
          unit = "bytes";
        })
        (statPanel {
          id = 2;
          title = "Failed backup units";
          expr = "sum(node_systemd_unit_state{name=~\"restic-backups-.*\\\\.service|backup-vaultwarden.service|forgejo-dump.service\", state=\"failed\"})";
          x = 6;
          y = 0;
        })
        (timeSeriesPanel {
          id = 3;
          title = "Disk reads";
          expr = "rate(node_disk_read_bytes_total[5m])";
          x = 0;
          y = 4;
          unit = "Bps";
        })
        (timeSeriesPanel {
          id = 4;
          title = "Disk writes";
          expr = "rate(node_disk_written_bytes_total[5m])";
          x = 12;
          y = 4;
          unit = "Bps";
        })
      ];
    }} "$out/storage-backup.json"
    cp ${dashboard {
      uid = "service-health";
      title = "Service health";
      panels = [
        (statPanel {
          id = 1;
          title = "Critical services active";
          expr = "sum(node_systemd_unit_state{name=~\"vaultwarden.service|nginx.service|grafana.service|prometheus.service|forgejo.service\", state=\"active\"})";
          x = 0;
          y = 0;
        })
        (statPanel {
          id = 2;
          title = "Failed units";
          expr = "sum(node_systemd_unit_state{state=\"failed\"})";
          x = 6;
          y = 0;
        })
        (statPanel {
          id = 3;
          title = "Dusk uptime";
          expr = "time() - node_boot_time_seconds{instance=\"dusk\"}";
          x = 12;
          y = 0;
          unit = "s";
        })
      ];
    }} "$out/service-health.json"
    cp ${dashboard {
      uid = "security-posture";
      title = "Security posture";
      panels = [
        (statPanel {
          id = 1;
          title = "Auditd active";
          expr = "node_systemd_unit_state{name=\"auditd.service\", state=\"active\"}";
          x = 0;
          y = 0;
        })
        (statPanel {
          id = 2;
          title = "AppArmor active";
          expr = "node_systemd_unit_state{name=\"apparmor.service\", state=\"active\"}";
          x = 6;
          y = 0;
        })
        (statPanel {
          id = 3;
          title = "SMART active";
          expr = "node_systemd_unit_state{name=\"smartd.service\", state=\"active\"}";
          x = 12;
          y = 0;
        })
        (statPanel {
          id = 4;
          title = "Btrfs scrub failures";
          expr = "sum(node_systemd_unit_state{name=~\"btrfs-scrub.*\\\\.service\", state=\"failed\"})";
          x = 18;
          y = 0;
        })
      ];
    }} "$out/security-posture.json"
  '';
in {
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = infraNetwork.dusk.ports.prometheus;
      alertmanagers = [
        {
          static_configs = [
            {
              targets = ["127.0.0.1:9093"];
            }
          ];
        }
      ];

      scrapeConfigs = [
        {
          job_name = "dusk";
          static_configs = [
            {
              targets = ["127.0.0.1:9100"];
              labels.instance = "dusk";
            }
          ];
        }
        {
          job_name = "shade";
          static_configs = [
            {
              targets = ["${infraNetwork.shade.wireguard.address}:${toString infraNetwork.shade.ports.nodeExporter}"];
              labels.instance = "shade";
            }
          ];
        }
      ];

      ruleFiles = [
        (pkgs.writeText "dusk-alerts.yml" ''
          groups:
            - name: dusk-services
              rules:
                - alert: DuskNodeExporterDown
                  expr: up{job="dusk"} == 0
                  for: 5m
                  labels:
                    severity: critical
                  annotations:
                    summary: "dusk node exporter is unreachable"

                - alert: ShadeNodeExporterDown
                  expr: up{job="shade"} == 0
                  for: 10m
                  labels:
                    severity: warning
                  annotations:
                    summary: "shade node exporter is unreachable from dusk"

                - alert: VaultwardenDown
                  expr: node_systemd_unit_state{name="vaultwarden.service", state="active"} != 1
                  for: 5m
                  labels:
                    severity: critical
                  annotations:
                    summary: "vaultwarden is not active on dusk"

                - alert: VaultwardenBackupFailed
                  expr: node_systemd_unit_state{name="backup-vaultwarden.service", state="failed"} == 1
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "vaultwarden backup unit failed on dusk"

                - alert: ForgejoDown
                  expr: node_systemd_unit_state{name="forgejo.service", state="active"} != 1
                  for: 5m
                  labels:
                    severity: critical
                  annotations:
                    summary: "forgejo is not active on dusk"

                - alert: ForgejoDumpFailed
                  expr: node_systemd_unit_state{name="forgejo-dump.service", state="failed"} == 1
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "forgejo dump unit failed on dusk"

                - alert: ResticBackupFailed
                  expr: node_systemd_unit_state{name=~"restic-backups-.*\\.service", state="failed"} == 1
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "a restic backup unit failed on {{ $labels.instance }}"

                - alert: DuskPersistLowSpace
                  expr: node_filesystem_avail_bytes{job="dusk", mountpoint="/persist", fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{job="dusk", mountpoint="/persist", fstype!~"tmpfs|overlay"} < 0.20
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "dusk /persist has less than 20% free space"

                - alert: SmartdDown
                  expr: node_systemd_unit_state{name="smartd.service", state="active"} != 1
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "smartd is not active on {{ $labels.instance }}"

                - alert: AuditdDown
                  expr: node_systemd_unit_state{name="auditd.service", state="active"} != 1
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "auditd is not active on {{ $labels.instance }}"

                - alert: AppArmorDown
                  expr: node_systemd_unit_state{name="apparmor.service", state="active"} != 1
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "apparmor is not active on {{ $labels.instance }}"

                - alert: BtrfsScrubFailed
                  expr: node_systemd_unit_state{name=~"btrfs-scrub.*\\.service", state="failed"} == 1
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "a Btrfs scrub unit failed on {{ $labels.instance }}"

                - alert: ShadeWireGuardDown
                  expr: node_systemd_unit_state{job="shade", name="wg-quick-wg0.service", state="active"} != 1
                  for: 10m
                  labels:
                    severity: warning
                  annotations:
                    summary: "shade WireGuard is not active"
        '')
      ];

      exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
        port = infraNetwork.dusk.ports.nodeExporter;
      };

      alertmanager = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9093;
        openFirewall = false;
        checkConfig = false;
        environmentFile = alertmanagerEnv;
        configuration = {
          global = {
            smtp_smarthost = "smtp.gmail.com:465";
            smtp_from = "Alertmanager <martonaronvarga@gmail.com>";
            smtp_auth_username = "martonaronvarga@gmail.com";
            smtp_auth_password = "$SMTP_PASSWORD";
            smtp_require_tls = true;
          };
          route = {
            receiver = "gmail";
            group_by = ["alertname" "instance"];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "12h";
          };
          receivers = [
            {
              name = "gmail";
              email_configs = [
                {
                  to = "admin@martonaronvarga.dev";
                  send_resolved = true;
                }
              ];
            }
          ];
        };
      };
    };

    grafana = {
      enable = true;
      settings = {
        analytics.reporting_enabled = false;
        security = {
          admin_email = "admin@martonaronvarga.dev";
          admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
          admin_user = "admin";
          secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        };
        server = {
          domain = "dusk";
          http_addr = infraNetwork.dusk.wireguard.address;
          http_port = infraNetwork.dusk.ports.grafana;
          root_url = "http://${infraNetwork.dusk.wireguard.address}:${toString infraNetwork.dusk.ports.grafana}/";
        };
        users = {
          allow_org_create = false;
          allow_sign_up = false;
        };
      };

      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          prune = false;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:9090";
              isDefault = true;
              editable = false;
            }
          ];
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "dusk";
              type = "file";
              disableDeletion = false;
              allowUiUpdates = false;
              options.path = dashboards;
            }
          ];
        };
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1week
    '';
  };

  environment.systemPackages = with pkgs; [
    htop
    iotop
    iftop
    nethogs
  ];

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.grafana
  ];

  systemd = {
    tmpfiles.rules = [
      "d /run/alertmanager 0700 root root -"
    ];

    services = {
      alertmanager-smtp-env = {
        description = "Prepare Alertmanager SMTP environment";
        wantedBy = ["multi-user.target"];
        before = ["alertmanager.service"];
        after = ["agenix.service"];
        wants = ["agenix.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          install -d -m 0700 -o root -g root /run/alertmanager
          password="$(cat ${lib.escapeShellArg config.age.secrets.forgejo-mailer-password.path})"
          printf 'SMTP_PASSWORD=%s\n' "$password" > ${lib.escapeShellArg alertmanagerEnv}
          chmod 0400 ${lib.escapeShellArg alertmanagerEnv}
        '';
      };

      alertmanager = {
        after = ["alertmanager-smtp-env.service"];
        requires = ["alertmanager-smtp-env.service"];
      };
    };
  };
}
