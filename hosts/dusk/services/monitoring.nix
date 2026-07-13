{
  config,
  infraNetwork,
  pkgs,
  ...
}: {
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = infraNetwork.dusk.ports.prometheus;

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

                - alert: ShadeResticBackupFailed
                  expr: node_systemd_unit_state{job="shade", name="restic-backups-shade-to-dusk.service", state="failed"} == 1
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "shade restic backup to dusk failed"

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

      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
          port = infraNetwork.dusk.ports.nodeExporter;
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
          prune = true;
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
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1week
    '';
  };

  # Monitoring tools
  environment.systemPackages = with pkgs; [
    htop
    iotop
    iftop
    nethogs
  ];

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.grafana
  ];
}
