{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  alertmanagerEnv = "/run/alertmanager/smtp.env";
  inherit (inventory) mail network;
  blackboxConfig = pkgs.writeText "blackbox.yml" ''
    modules:
      public_website:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["Marton"]
      public_vault:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["Vaultwarden|Web Vault"]
      public_forge:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["Forgejo|Personal software forge"]
      public_matrix_client:
        prober: http
        timeout: 15s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ['"versions"']
      public_matrix_federation:
        prober: http
        timeout: 15s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ['"server"']
      public_matrix_well_known_client:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["matrix.martonaronvarga.dev"]
      public_matrix_well_known_server:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["matrix.martonaronvarga.dev:443"]
      public_matrix_support:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          fail_if_body_not_matches_regexp: ["@usu:martonaronvarga.dev"]
      backend_matrix:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_body_not_matches_regexp: ['"versions"']
      origin_website:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          headers: { Host: "martonaronvarga.dev" }
          tls_config: { server_name: "martonaronvarga.dev" }
      origin_vault:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          headers: { Host: "vault.martonaronvarga.dev" }
          tls_config: { server_name: "vault.martonaronvarga.dev" }
      origin_forge:
        prober: http
        timeout: 10s
        http:
          preferred_ip_protocol: ip4
          fail_if_not_ssl: true
          headers: { Host: "git.martonaronvarga.dev" }
          tls_config: { server_name: "git.martonaronvarga.dev" }
      icmp_ipv4:
        prober: icmp
        timeout: 5s
        icmp:
          preferred_ip_protocol: ip4
          ip_protocol_fallback: false
      dns_quad9_dot:
        prober: dns
        timeout: 5s
        dns:
          preferred_ip_protocol: ip4
          ip_protocol_fallback: false
          transport_protocol: tcp
          dns_over_tls: true
          tls_config: { server_name: "dns.quad9.net" }
          query_name: "martonaronvarga.dev"
          query_type: A
      dns_cloudflare_dot:
        prober: dns
        timeout: 5s
        dns:
          preferred_ip_protocol: ip4
          ip_protocol_fallback: false
          transport_protocol: tcp
          dns_over_tls: true
          tls_config: { server_name: "cloudflare-dns.com" }
          query_name: "martonaronvarga.dev"
          query_type: A
  '';
  mkBlackboxScrape = {
    name,
    module,
    target,
  }: {
    job_name = "blackbox-${name}";
    metrics_path = "/probe";
    params.module = [module];
    scrape_interval = "1m";
    static_configs = [{targets = [target];}];
    relabel_configs = [
      {
        source_labels = ["__address__"];
        target_label = "__param_target";
      }
      {
        source_labels = ["__param_target"];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "127.0.0.1:9115";
      }
    ];
  };
  dashboards = import ./grafana-dashboards.nix {inherit lib pkgs;};
in {
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = network.dusk.ports.prometheus;
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
              targets = ["${network.shade.wireguard.address}:${toString network.shade.ports.nodeExporter}"];
              labels.instance = "shade";
            }
          ];
        }
        {
          job_name = "gloam";
          static_configs = [
            {
              targets = ["${network.gloam.wireguard.address}:9100"];
              labels.instance = "gloam";
            }
          ];
        }
        (mkBlackboxScrape {
          name = "public-website";
          module = "public_website";
          target = "https://martonaronvarga.dev/";
        })
        (mkBlackboxScrape {
          name = "public-vault";
          module = "public_vault";
          target = "https://vault.martonaronvarga.dev/";
        })
        (mkBlackboxScrape {
          name = "public-forge";
          module = "public_forge";
          target = "https://git.martonaronvarga.dev/";
        })
        (mkBlackboxScrape {
          name = "public-matrix-client";
          module = "public_matrix_client";
          target = "https://matrix.martonaronvarga.dev/_matrix/client/versions";
        })
        (mkBlackboxScrape {
          name = "public-matrix-federation";
          module = "public_matrix_federation";
          target = "https://matrix.martonaronvarga.dev/_matrix/federation/v1/version";
        })
        (mkBlackboxScrape {
          name = "public-matrix-well-known-client";
          module = "public_matrix_well_known_client";
          target = "https://martonaronvarga.dev/.well-known/matrix/client";
        })
        (mkBlackboxScrape {
          name = "public-matrix-well-known-server";
          module = "public_matrix_well_known_server";
          target = "https://martonaronvarga.dev/.well-known/matrix/server";
        })
        (mkBlackboxScrape {
          name = "public-matrix-support";
          module = "public_matrix_support";
          target = "https://martonaronvarga.dev/.well-known/matrix/support";
        })
        (mkBlackboxScrape {
          name = "backend-matrix-client";
          module = "backend_matrix";
          target = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.matrix}/_matrix/client/versions";
        })
        (mkBlackboxScrape {
          name = "origin-website";
          module = "origin_website";
          target = "https://${network.gloam.wireguard.address}/";
        })
        (mkBlackboxScrape {
          name = "origin-vault";
          module = "origin_vault";
          target = "https://${network.gloam.wireguard.address}/";
        })
        (mkBlackboxScrape {
          name = "origin-forge";
          module = "origin_forge";
          target = "https://${network.gloam.wireguard.address}/";
        })
        (mkBlackboxScrape {
          name = "gateway";
          module = "icmp_ipv4";
          target = "192.168.0.1";
        })
        (mkBlackboxScrape {
          name = "internet-cloudflare";
          module = "icmp_ipv4";
          target = "1.1.1.1";
        })
        (mkBlackboxScrape {
          name = "internet-quad9";
          module = "icmp_ipv4";
          target = "9.9.9.9";
        })
        (mkBlackboxScrape {
          name = "dns-cloudflare";
          module = "dns_cloudflare_dot";
          target = "1.1.1.1:853";
        })
        (mkBlackboxScrape {
          name = "dns-quad9";
          module = "dns_quad9_dot";
          target = "9.9.9.9:853";
        })
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

                - alert: ForgejoRunnerDown
                  expr: node_systemd_unit_state{name="gitea-runner-dusk.service", state="active"} != 1
                  for: 10m
                  labels:
                    severity: warning
                  annotations:
                    summary: "the owner-scoped Forgejo runner is not active on dusk"

                - alert: ContinuwuityDown
                  expr: node_systemd_unit_state{name="continuwuity.service", state="active"} != 1
                  for: 5m
                  labels:
                    severity: critical
                  annotations:
                    summary: "Continuwuity is not active on dusk"

                - alert: ContinuwuityMaintenanceFailed
                  expr: node_systemd_unit_state{name=~"continuwuity-(maintenance|weekly-archive)\\.service", state="failed"} == 1
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "a Continuwuity maintenance unit failed on dusk"

                - alert: ContinuwuityBackupStale
                  expr: (time() - continuwuity_backup_last_success_seconds > 36 * 60 * 60) or absent(continuwuity_backup_last_success_seconds)
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "Continuwuity database backup is older than 36 hours"

                - alert: ContinuwuityWeeklyArchiveStale
                  expr: (time() - continuwuity_weekly_archive_last_success_seconds > 9 * 24 * 60 * 60) or absent(continuwuity_weekly_archive_last_success_seconds)
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "Continuwuity weekly archive is older than nine days"

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

                - alert: PublicEndpointDown
                  expr: probe_success{job=~"blackbox-(public|origin|backend)-.*"} == 0
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "public or origin probe failed for {{ $labels.instance }}"

                - alert: DuskGatewayDown
                  expr: probe_success{job="blackbox-gateway"} == 0
                  for: 2m
                  labels:
                    severity: critical
                  annotations:
                    summary: "dusk cannot reach its local gateway"

                - alert: DuskInternetPathDown
                  expr: max(probe_success{job=~"blackbox-internet-.*"}) == 0
                  for: 3m
                  labels:
                    severity: critical
                  annotations:
                    summary: "dusk cannot reach independent internet targets by IP"

                - alert: DuskDnsResolverDown
                  expr: probe_success{job=~"blackbox-dns-.*"} == 0
                  for: 5m
                  labels:
                    severity: warning
                  annotations:
                    summary: "encrypted DNS probe failed for {{ $labels.job }}"

                - alert: DuskAllDnsResolversDown
                  expr: max(probe_success{job=~"blackbox-dns-.*"}) == 0
                  for: 3m
                  labels:
                    severity: critical
                  annotations:
                    summary: "all configured encrypted DNS resolvers are unreachable"

                - alert: DuskWireGuardOriginDown
                  expr: max(probe_success{job=~"blackbox-origin-.*"}) == 0
                  for: 3m
                  labels:
                    severity: critical
                  annotations:
                    summary: "dusk cannot reach the gloam origin over WireGuard"

                - alert: DuskEthernetCarrierChanged
                  expr: increase(node_network_carrier_changes_total{instance="dusk",device="enp0s31f6"}[10m]) > 0
                  for: 1m
                  labels:
                    severity: warning
                  annotations:
                    summary: "dusk Ethernet carrier changed in the last ten minutes"

                - alert: PublicCertificateExpiring
                  expr: probe_ssl_earliest_cert_expiry - time() < 21 * 24 * 60 * 60
                  for: 15m
                  labels:
                    severity: warning
                  annotations:
                    summary: "TLS certificate expires within 21 days for {{ $labels.instance }}"
        '')
      ];

      exporters.blackbox = {
        enable = true;
        listenAddress = "127.0.0.1";
        configFile = blackboxConfig;
      };

      exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
        extraFlags = ["--collector.textfile.directory=/var/lib/prometheus-node-exporter-textfiles"];
        port = network.dusk.ports.nodeExporter;
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
            smtp_from = "Alertmanager <${mail.sender}>";
            smtp_auth_username = mail.sender;
            smtp_auth_password = "$SMTP_PASSWORD";
            smtp_require_tls = true;
          };
          route = {
            receiver = "discard";
            group_by = ["alertname" "instance"];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "12h";
            routes = [
              {
                receiver = "gmail";
                matchers = ["severity=~\"warning|critical\""];
              }
            ];
          };
          receivers = [
            {
              name = "discard";
            }
            {
              name = "gmail";
              email_configs = [
                {
                  to = mail.alertRecipient;
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
          admin_email = mail.alertRecipient;
          admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
          admin_user = "admin";
          secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        };
        server = {
          domain = "dusk";
          http_addr = network.dusk.wireguard.address;
          http_port = network.dusk.ports.grafana;
          root_url = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.grafana}/";
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
              uid = "PBFA97CFB590B2093";
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
      SystemMaxUse=1G
      MaxRetentionSec=30day
    '';
  };

  environment.systemPackages = with pkgs; [
    htop
    iotop
    iftop
    nethogs
  ];

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.dusk.ports.grafana
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
