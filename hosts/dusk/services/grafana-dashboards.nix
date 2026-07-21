{
  lib,
  pkgs,
}: let
  green = [
    {
      color = "green";
      value = null;
    }
  ];
  health = [
    {
      color = "red";
      value = null;
    }
    {
      color = "green";
      value = 1;
    }
  ];
  problems = [
    {
      color = "green";
      value = null;
    }
    {
      color = "orange";
      value = 1;
    }
    {
      color = "red";
      value = 2;
    }
  ];
  utilization = [
    {
      color = "green";
      value = null;
    }
    {
      color = "orange";
      value = 0.7;
    }
    {
      color = "red";
      value = 0.9;
    }
  ];
  healthMappings = [
    {
      type = "value";
      options = {
        "0" = {
          color = "red";
          text = "DOWN";
        };
        "1" = {
          color = "green";
          text = "UP";
        };
      };
    }
  ];
  dashboardLinks =
    map (link: {
      asDropdown = false;
      icon = "external link";
      includeVars = true;
      keepTime = true;
      tags = [];
      targetBlank = false;
      type = "link";
      inherit (link) title url;
    }) [
      {
        title = "Overview";
        url = "/d/fleet-overview";
      }
      {
        title = "Hosts";
        url = "/d/host-resources";
      }
      {
        title = "Services";
        url = "/d/service-health";
      }
      {
        title = "Storage & backups";
        url = "/d/storage-backup";
      }
      {
        title = "Security";
        url = "/d/security-posture";
      }
      {
        title = "Matrix";
        url = "/d/matrix-service";
      }
    ];
  nodeVariable = {
    name = "node";
    label = "Node";
    type = "query";
    datasource = {
      type = "prometheus";
      uid = "prometheus";
    };
    definition = "label_values(node_uname_info, instance)";
    query = {
      query = "label_values(node_uname_info, instance)";
      refId = "PrometheusVariableQueryEditor-VariableQuery";
    };
    current = {
      selected = true;
      text = ["All"];
      value = ["$__all"];
    };
    includeAll = true;
    allValue = ".*";
    multi = true;
    refresh = 1;
    sort = 1;
  };
  mkDashboard = {
    uid,
    title,
    description,
    panels,
    variables ? [],
    from ? "now-24h",
  }:
    pkgs.writeText "${uid}.json" (builtins.toJSON {
      inherit uid title description panels;
      editable = false;
      graphTooltip = 1;
      links = dashboardLinks;
      refresh = "1m";
      schemaVersion = 41;
      tags = ["dusk" "operations" "provisioned"];
      templating.list = variables;
      time = {
        inherit from;
        to = "now";
      };
      timezone = "browser";
      version = 2;
    });
  text = {
    id,
    title,
    content,
    y,
    h ? 3,
  }: {
    inherit id title;
    type = "text";
    gridPos = {
      inherit h y;
      w = 24;
      x = 0;
    };
    options = {
      mode = "markdown";
      inherit content;
    };
  };
  row = {
    id,
    title,
    y,
  }: {
    inherit id title;
    type = "row";
    collapsed = false;
    gridPos = {
      h = 1;
      w = 24;
      x = 0;
      inherit y;
    };
    panels = [];
  };
  stat = {
    id,
    title,
    description,
    expr,
    x,
    y,
    w ? 6,
    h ? 4,
    unit ? "short",
    legend ? "{{instance}}",
    steps ? problems,
    mappings ? [],
    min ? null,
    max ? null,
    noValue ? "N/A",
    colorMode ? "background",
  }: {
    inherit id title description;
    type = "stat";
    gridPos = {inherit h w x y;};
    targets = [
      {
        refId = "A";
        inherit expr;
        legendFormat = legend;
        instant = true;
        range = false;
      }
    ];
    fieldConfig.defaults =
      {
        inherit unit mappings noValue;
        color.mode = "thresholds";
        thresholds = {
          mode = "absolute";
          inherit steps;
        };
      }
      // lib.optionalAttrs (min != null) {inherit min;}
      // lib.optionalAttrs (max != null) {inherit max;};
    options = {
      inherit colorMode;
      graphMode = "none";
      justifyMode = "auto";
      orientation = "auto";
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
      textMode = "auto";
      wideLayout = true;
    };
  };
  series = {
    id,
    title,
    description,
    expr,
    x,
    y,
    w ? 12,
    h ? 7,
    unit ? "short",
    legend ? "{{instance}}",
    min ? null,
    max ? null,
    fill ? 10,
  }: {
    inherit id title description;
    type = "timeseries";
    gridPos = {inherit h w x y;};
    targets = [
      {
        refId = "A";
        inherit expr;
        legendFormat = legend;
      }
    ];
    fieldConfig.defaults =
      {
        inherit unit;
        color.mode = "palette-classic";
        custom = {
          axisCenteredZero = false;
          axisColorMode = "text";
          axisLabel = "";
          axisPlacement = "auto";
          barAlignment = 0;
          drawStyle = "line";
          fillOpacity = fill;
          gradientMode = "none";
          hideFrom = {
            legend = false;
            tooltip = false;
            viz = false;
          };
          lineInterpolation = "linear";
          lineWidth = 2;
          pointSize = 4;
          scaleDistribution.type = "linear";
          showPoints = "never";
          spanNulls = 300000;
          stacking = {
            group = "A";
            mode = "none";
          };
          thresholdsStyle.mode = "off";
        };
        thresholds = {
          mode = "absolute";
          steps = green;
        };
      }
      // lib.optionalAttrs (min != null) {inherit min;}
      // lib.optionalAttrs (max != null) {inherit max;};
    options = {
      legend = {
        calcs = ["lastNotNull" "max"];
        displayMode = "table";
        placement = "bottom";
        showLegend = true;
      };
      tooltip = {
        hideZeros = false;
        mode = "multi";
        sort = "desc";
      };
    };
  };
  overview = mkDashboard {
    uid = "fleet-overview";
    title = "Operations overview";
    description = "Active incidents, user-visible endpoints, critical services, and fleet saturation.";
    panels = [
      (text {
        id = 1;
        title = "Start here";
        y = 0;
        content = "**Check alerts and probes first.** If users are affected, open Services. If a node is saturated, open Hosts. If data is at risk, open Storage & backups. Shade is a laptop and may legitimately be absent.";
      })
      (row {
        id = 2;
        title = "Current state";
        y = 3;
      })
      (stat {
        id = 3;
        title = "Firing alerts";
        description = "Prometheus alerts currently firing; zero is healthy.";
        expr = "count(ALERTS{alertstate=\"firing\"})";
        x = 0;
        y = 4;
      })
      (stat {
        id = 4;
        title = "Infrastructure nodes";
        description = "Reachable exporters for dusk, shade, and gloam.";
        expr = "sum(up{job=~\"dusk|shade|gloam\"})";
        x = 6;
        y = 4;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 2;
          }
          {
            color = "green";
            value = 3;
          }
        ];
      })
      (stat {
        id = 5;
        title = "Probe availability";
        description = "Current success ratio across every blackbox probe.";
        expr = "sum(probe_success) / count(probe_success)";
        x = 12;
        y = 4;
        unit = "percentunit";
        min = 0;
        max = 1;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 0.95;
          }
          {
            color = "green";
            value = 1;
          }
        ];
      })
      (stat {
        id = 6;
        title = "Critical services";
        description = "Active fraction of six core dusk services.";
        expr = "sum(node_systemd_unit_state{instance=\"dusk\",name=~\"vaultwarden.service|nginx.service|grafana.service|prometheus.service|forgejo.service|continuwuity.service\",state=\"active\"}) / 6";
        x = 18;
        y = 4;
        unit = "percentunit";
        min = 0;
        max = 1;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 0.99;
          }
          {
            color = "green";
            value = 1;
          }
        ];
      })
      (row {
        id = 7;
        title = "User-visible health";
        y = 8;
      })
      (stat {
        id = 8;
        title = "Endpoint status";
        description = "Current result for each public, origin, and backend check.";
        expr = "probe_success";
        x = 0;
        y = 9;
        w = 24;
        h = 7;
        legend = "{{job}}";
        steps = health;
        mappings = healthMappings;
      })
      (series {
        id = 9;
        title = "Probe latency";
        description = "Compare public versus origin/backend duration to localize slowness.";
        expr = "probe_duration_seconds";
        x = 0;
        y = 16;
        w = 24;
        unit = "s";
        legend = "{{job}}";
      })
      (row {
        id = 10;
        title = "Fleet saturation";
        y = 23;
      })
      (series {
        id = 11;
        title = "CPU utilization";
        description = "Non-idle CPU time normalized across logical cores.";
        expr = "1 - avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[$__rate_interval]))";
        x = 0;
        y = 24;
        unit = "percentunit";
        min = 0;
        max = 1;
      })
      (series {
        id = 12;
        title = "Memory utilization";
        description = "Used memory after reclaimable cache is accounted for.";
        expr = "1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes";
        x = 12;
        y = 24;
        unit = "percentunit";
        min = 0;
        max = 1;
      })
      (series {
        id = 13;
        title = "Load per core";
        description = "One-minute runnable load normalized by logical CPU count.";
        expr = "node_load1 / on(instance) count by (instance) (node_cpu_seconds_total{mode=\"idle\"})";
        x = 0;
        y = 31;
        min = 0;
      })
      (series {
        id = 14;
        title = "Primary filesystem utilization";
        description = "Used fraction of root filesystems and dusk /persist.";
        expr = "1 - node_filesystem_avail_bytes{mountpoint=~\"/|/persist\",fstype!~\"tmpfs|overlay|squashfs|ramfs\"} / node_filesystem_size_bytes{mountpoint=~\"/|/persist\",fstype!~\"tmpfs|overlay|squashfs|ramfs\"}";
        x = 12;
        y = 31;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "{{instance}} {{mountpoint}}";
      })
    ];
  };
  hosts = mkDashboard {
    uid = "host-resources";
    title = "Host resources";
    description = "USE-oriented CPU, memory, storage, network, thermal, power, and uptime drill-down.";
    variables = [nodeVariable];
    panels = [
      (text {
        id = 1;
        title = "Scope";
        y = 0;
        content = "Choose nodes above. **Utilization** shows how busy a resource is, **saturation** shows queued work, and error rates show faults. Rate queries use Grafana's adaptive `$__rate_interval`.";
      })
      (row {
        id = 2;
        title = "At a glance";
        y = 3;
      })
      (stat {
        id = 3;
        title = "Exporter status";
        description = "Prometheus scrape state for selected nodes.";
        expr = "up{job=~\"dusk|shade|gloam\",instance=~\"$node\"}";
        x = 0;
        y = 4;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 4;
        title = "Uptime";
        description = "Elapsed time since each node booted.";
        expr = "time() - node_boot_time_seconds{instance=~\"$node\"}";
        x = 8;
        y = 4;
        w = 8;
        unit = "s";
        steps = green;
        colorMode = "value";
      })
      (stat {
        id = 5;
        title = "Maximum temperature";
        description = "Highest positive hardware-monitor temperature per node.";
        expr = "max by (instance) (node_hwmon_temp_celsius{instance=~\"$node\"} > 0)";
        x = 16;
        y = 4;
        w = 8;
        unit = "celsius";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 75;
          }
          {
            color = "red";
            value = 90;
          }
        ];
      })
      (row {
        id = 6;
        title = "CPU and memory";
        y = 8;
      })
      (series {
        id = 7;
        title = "CPU utilization";
        description = "Non-idle CPU percentage by node.";
        expr = "1 - avg by (instance) (rate(node_cpu_seconds_total{instance=~\"$node\",mode=\"idle\"}[$__rate_interval]))";
        x = 0;
        y = 9;
        unit = "percentunit";
        min = 0;
        max = 1;
      })
      (series {
        id = 8;
        title = "Load per CPU core";
        description = "Sustained values above 1 indicate queued work.";
        expr = "node_load1{instance=~\"$node\"} / on(instance) count by (instance) (node_cpu_seconds_total{instance=~\"$node\",mode=\"idle\"})";
        x = 12;
        y = 9;
        min = 0;
      })
      (series {
        id = 9;
        title = "Memory utilization";
        description = "Used memory after reclaimable cache.";
        expr = "1 - node_memory_MemAvailable_bytes{instance=~\"$node\"} / node_memory_MemTotal_bytes{instance=~\"$node\"}";
        x = 0;
        y = 16;
        unit = "percentunit";
        min = 0;
        max = 1;
      })
      (series {
        id = 10;
        title = "Swap utilization";
        description = "Used swap on nodes with swap configured.";
        expr = "(1 - node_memory_SwapFree_bytes{instance=~\"$node\"} / node_memory_SwapTotal_bytes{instance=~\"$node\"}) and node_memory_SwapTotal_bytes{instance=~\"$node\"} > 0";
        x = 12;
        y = 16;
        unit = "percentunit";
        min = 0;
        max = 1;
      })
      (row {
        id = 11;
        title = "Storage";
        y = 23;
      })
      (series {
        id = 12;
        title = "Filesystem utilization";
        description = "Used fraction of durable primary filesystems.";
        expr = "1 - node_filesystem_avail_bytes{instance=~\"$node\",mountpoint=~\"/|/persist\",fstype!~\"tmpfs|overlay|squashfs|ramfs\"} / node_filesystem_size_bytes{instance=~\"$node\",mountpoint=~\"/|/persist\",fstype!~\"tmpfs|overlay|squashfs|ramfs\"}";
        x = 0;
        y = 24;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "{{instance}} {{mountpoint}}";
      })
      (series {
        id = 13;
        title = "Physical disk busy time";
        description = "Fraction of wall time spent servicing physical-disk I/O.";
        expr = "rate(node_disk_io_time_seconds_total{instance=~\"$node\",device=~\"sd[a-z]|nvme[0-9]+n[0-9]+\"}[$__rate_interval])";
        x = 12;
        y = 24;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "{{instance}} {{device}}";
      })
      (series {
        id = 14;
        title = "Disk throughput";
        description = "Combined physical-disk read and write throughput.";
        expr = "sum by (instance) (rate(node_disk_read_bytes_total{instance=~\"$node\",device=~\"sd[a-z]|nvme[0-9]+n[0-9]+\"}[$__rate_interval]) + rate(node_disk_written_bytes_total{instance=~\"$node\",device=~\"sd[a-z]|nvme[0-9]+n[0-9]+\"}[$__rate_interval]))";
        x = 0;
        y = 31;
        unit = "Bps";
      })
      (series {
        id = 15;
        title = "I/O weighted queue time";
        description = "Weighted seconds per second spent queued or servicing I/O.";
        expr = "rate(node_disk_io_time_weighted_seconds_total{instance=~\"$node\",device=~\"sd[a-z]|nvme[0-9]+n[0-9]+\"}[$__rate_interval])";
        x = 12;
        y = 31;
        unit = "s";
        min = 0;
        legend = "{{instance}} {{device}}";
      })
      (row {
        id = 16;
        title = "Network and power";
        y = 38;
      })
      (series {
        id = 17;
        title = "Network receive";
        description = "Inbound traffic excluding loopback and common virtual interfaces.";
        expr = "sum by (instance) (rate(node_network_receive_bytes_total{instance=~\"$node\",device!~\"lo|veth.*|docker.*|br-.*\"}[$__rate_interval]))";
        x = 0;
        y = 39;
        unit = "Bps";
      })
      (series {
        id = 18;
        title = "Network transmit";
        description = "Outbound traffic excluding loopback and common virtual interfaces.";
        expr = "sum by (instance) (rate(node_network_transmit_bytes_total{instance=~\"$node\",device!~\"lo|veth.*|docker.*|br-.*\"}[$__rate_interval]))";
        x = 12;
        y = 39;
        unit = "Bps";
      })
      (series {
        id = 19;
        title = "Network errors and drops";
        description = "Receive/transmit errors and drops; healthy links stay at zero.";
        expr = "sum by (instance) (rate(node_network_receive_errs_total{instance=~\"$node\"}[$__rate_interval]) + rate(node_network_transmit_errs_total{instance=~\"$node\"}[$__rate_interval]) + rate(node_network_receive_drop_total{instance=~\"$node\"}[$__rate_interval]) + rate(node_network_transmit_drop_total{instance=~\"$node\"}[$__rate_interval]))";
        x = 0;
        y = 46;
        min = 0;
      })
      (series {
        id = 20;
        title = "Battery capacity";
        description = "Charge level for laptop-class nodes.";
        expr = "node_power_supply_capacity{instance=~\"$node\"} / 100";
        x = 12;
        y = 46;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "{{instance}} {{power_supply}}";
      })
    ];
  };
  services = mkDashboard {
    uid = "service-health";
    title = "Service health";
    description = "User-visible success, edge versus backend latency, HTTP phases, TLS lifetime, and dusk service state.";
    panels = [
      (text {
        id = 1;
        title = "Troubleshooting path";
        y = 0;
        content = "A failed **public** probe means the user path is broken. A healthy origin with a failed public probe points toward DNS/CDN/TLS; a failed origin points toward Gloam, WireGuard, or Dusk. Matrix also has a direct backend probe.";
      })
      (row {
        id = 2;
        title = "Current service state";
        y = 3;
      })
      (stat {
        id = 3;
        title = "Dusk services";
        description = "Active state for every critical dusk service.";
        expr = "node_systemd_unit_state{instance=\"dusk\",name=~\"vaultwarden.service|nginx.service|grafana.service|prometheus.service|forgejo.service|continuwuity.service\",state=\"active\"}";
        x = 0;
        y = 4;
        w = 24;
        h = 5;
        legend = "{{name}}";
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 4;
        title = "Public and origin probes";
        description = "Current result of every service probe.";
        expr = "probe_success";
        x = 0;
        y = 9;
        w = 24;
        h = 7;
        legend = "{{job}}";
        steps = health;
        mappings = healthMappings;
      })
      (row {
        id = 5;
        title = "Availability and latency";
        y = 16;
      })
      (series {
        id = 6;
        title = "Probe availability";
        description = "One is success and zero is failure at each probe interval.";
        expr = "probe_success";
        x = 0;
        y = 17;
        unit = "bool";
        min = 0;
        max = 1;
        legend = "{{job}}";
        fill = 20;
      })
      (series {
        id = 7;
        title = "Probe latency";
        description = "Full probe duration; compare public and origin variants.";
        expr = "probe_duration_seconds";
        x = 12;
        y = 17;
        unit = "s";
        legend = "{{job}}";
      })
      (series {
        id = 8;
        title = "HTTP phase duration";
        description = "DNS, connect, TLS, processing, and transfer time for public probes.";
        expr = "probe_http_duration_seconds{job=~\"blackbox-public-.*\"}";
        x = 0;
        y = 24;
        unit = "s";
        legend = "{{job}} {{phase}}";
      })
      (series {
        id = 9;
        title = "HTTP response status";
        description = "Final status code returned by each HTTP probe.";
        expr = "probe_http_status_code";
        x = 12;
        y = 24;
        legend = "{{job}}";
        fill = 0;
      })
      (row {
        id = 10;
        title = "TLS";
        y = 31;
      })
      (stat {
        id = 11;
        title = "Certificate lifetime remaining";
        description = "Days until the earliest certificate in each TLS chain expires.";
        expr = "(probe_ssl_earliest_cert_expiry - time()) / 86400";
        x = 0;
        y = 32;
        w = 24;
        h = 6;
        unit = "d";
        legend = "{{job}}";
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 21;
          }
          {
            color = "green";
            value = 30;
          }
        ];
      })
    ];
  };
  storage = mkDashboard {
    uid = "storage-backup";
    title = "Storage and backup";
    description = "Capacity, filesystem integrity, disk pressure, backup freshness, and failed jobs.";
    from = "now-7d";
    panels = [
      (text {
        id = 1;
        title = "Data-safety status";
        y = 0;
        content = "A successful job is not the same as a recoverable backup. Recovery also requires an **independent copy and a tested restore**. The external backup remains visibly unconfigured until its success metric exists.";
      })
      (row {
        id = 2;
        title = "Capacity and integrity";
        y = 3;
      })
      (stat {
        id = 3;
        title = "/persist used";
        description = "Dusk persistent-storage utilization.";
        expr = "1 - node_filesystem_avail_bytes{instance=\"dusk\",mountpoint=\"/persist\"} / node_filesystem_size_bytes{instance=\"dusk\",mountpoint=\"/persist\"}";
        x = 0;
        y = 4;
        unit = "percentunit";
        min = 0;
        max = 1;
        steps = utilization;
      })
      (stat {
        id = 4;
        title = "/persist available";
        description = "Bytes available to ordinary processes on /persist.";
        expr = "node_filesystem_avail_bytes{instance=\"dusk\",mountpoint=\"/persist\"}";
        x = 6;
        y = 4;
        unit = "bytes";
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 107374182400;
          }
          {
            color = "green";
            value = 214748364800;
          }
        ];
      })
      (stat {
        id = 5;
        title = "Failed backup units";
        description = "Backup-related services currently failed.";
        expr = "sum(node_systemd_unit_state{name=~\"restic-backups-.*\\\\.service|backup-vaultwarden.service|forgejo-dump.service|continuwuity-(maintenance|weekly-archive)\\\\.service\",state=\"failed\"})";
        x = 12;
        y = 4;
      })
      (stat {
        id = 6;
        title = "Filesystem errors";
        description = "Filesystem statistics that node_exporter could not collect on dusk.";
        expr = "sum(node_filesystem_device_error{instance=\"dusk\"})";
        x = 18;
        y = 4;
      })
      (row {
        id = 7;
        title = "Backup freshness";
        y = 8;
      })
      (stat {
        id = 8;
        title = "Matrix database";
        description = "Age of the latest online database backup.";
        expr = "time() - continuwuity_backup_last_success_seconds";
        x = 0;
        y = 9;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 86400;
          }
          {
            color = "red";
            value = 129600;
          }
        ];
      })
      (stat {
        id = 9;
        title = "Matrix weekly archive";
        description = "Age of the latest compressed database and media archive.";
        expr = "time() - continuwuity_weekly_archive_last_success_seconds";
        x = 6;
        y = 9;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 604800;
          }
          {
            color = "red";
            value = 777600;
          }
        ];
      })
      (stat {
        id = 10;
        title = "Vaultwarden timer";
        description = "Time since the nightly backup timer last fired.";
        expr = "time() - node_systemd_timer_last_trigger_seconds{instance=\"dusk\",name=\"backup-vaultwarden.timer\"}";
        x = 12;
        y = 9;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 86400;
          }
          {
            color = "red";
            value = 129600;
          }
        ];
      })
      (stat {
        id = 11;
        title = "Forgejo dump timer";
        description = "Time since the daily dump timer last fired.";
        expr = "time() - node_systemd_timer_last_trigger_seconds{instance=\"dusk\",name=\"forgejo-dump.timer\"}";
        x = 18;
        y = 9;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 86400;
          }
          {
            color = "red";
            value = 129600;
          }
        ];
      })
      (stat {
        id = 12;
        title = "Shade Restic timer";
        description = "Time since Shade triggered its Restic backup; N/A while Shade is off.";
        expr = "time() - node_systemd_timer_last_trigger_seconds{instance=\"shade\",name=\"restic-backups-shade-to-dusk.timer\"}";
        x = 0;
        y = 13;
        w = 8;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 172800;
          }
          {
            color = "red";
            value = 604800;
          }
        ];
      })
      (stat {
        id = 13;
        title = "External backup";
        description = "Age of the encrypted removable backup; N/A means not configured.";
        expr = "time() - dusk_external_backup_last_success_seconds";
        x = 8;
        y = 13;
        w = 8;
        unit = "s";
        noValue = "NOT CONFIGURED";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 1209600;
          }
          {
            color = "red";
            value = 2592000;
          }
        ];
      })
      (stat {
        id = 14;
        title = "Weekly archives retained";
        description = "Count of retained compressed Matrix archives.";
        expr = "continuwuity_weekly_archive_count";
        x = 16;
        y = 13;
        w = 8;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 1;
          }
          {
            color = "green";
            value = 2;
          }
        ];
      })
      (row {
        id = 15;
        title = "Storage behavior";
        y = 17;
      })
      (series {
        id = 16;
        title = "Dusk disk throughput";
        description = "Combined physical-disk reads and writes.";
        expr = "rate(node_disk_read_bytes_total{instance=\"dusk\",device=\"sda\"}[$__rate_interval]) + rate(node_disk_written_bytes_total{instance=\"dusk\",device=\"sda\"}[$__rate_interval])";
        x = 0;
        y = 18;
        unit = "Bps";
        legend = "total";
      })
      (series {
        id = 17;
        title = "Dusk disk saturation";
        description = "Fraction of wall time the disk is busy.";
        expr = "rate(node_disk_io_time_seconds_total{instance=\"dusk\",device=\"sda\"}[$__rate_interval])";
        x = 12;
        y = 18;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "sda";
      })
      (series {
        id = 18;
        title = "/persist utilization trend";
        description = "Seven-day capacity trend for storage planning.";
        expr = "1 - node_filesystem_avail_bytes{instance=\"dusk\",mountpoint=\"/persist\"} / node_filesystem_size_bytes{instance=\"dusk\",mountpoint=\"/persist\"}";
        x = 0;
        y = 25;
        w = 24;
        unit = "percentunit";
        min = 0;
        max = 1;
        legend = "/persist";
      })
    ];
  };
  security = mkDashboard {
    uid = "security-posture";
    title = "Security posture";
    description = "Hardening services, failed units, clock synchronization, filesystem faults, and WireGuard state.";
    panels = [
      (text {
        id = 1;
        title = "Interpretation";
        y = 0;
        content = "This shows **detectable controls**, not proof of security. A green tile means the expected service or condition is present. Use the security audit for controls not represented by metrics.";
      })
      (row {
        id = 2;
        title = "Hardening controls";
        y = 3;
      })
      (stat {
        id = 3;
        title = "Auditd";
        description = "Audit daemon state on NixOS nodes.";
        expr = "node_systemd_unit_state{name=\"auditd.service\",state=\"active\"}";
        x = 0;
        y = 4;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 4;
        title = "AppArmor";
        description = "AppArmor policy-loader state on NixOS nodes.";
        expr = "node_systemd_unit_state{name=\"apparmor.service\",state=\"active\"}";
        x = 8;
        y = 4;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 5;
        title = "SMART monitoring";
        description = "smartd state on managed hosts.";
        expr = "node_systemd_unit_state{name=\"smartd.service\",state=\"active\"}";
        x = 16;
        y = 4;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (row {
        id = 6;
        title = "Fault indicators";
        y = 8;
      })
      (stat {
        id = 7;
        title = "Failed systemd units";
        description = "Any nonzero value needs investigation.";
        expr = "sum by (instance) (node_systemd_unit_state{state=\"failed\"})";
        x = 0;
        y = 9;
        w = 8;
      })
      (stat {
        id = 8;
        title = "Btrfs scrub failures";
        description = "Scrub units currently failed.";
        expr = "sum(node_systemd_unit_state{name=~\"btrfs-scrub.*\\\\.service\",state=\"failed\"})";
        x = 8;
        y = 9;
        w = 8;
      })
      (stat {
        id = 9;
        title = "Filesystem collection errors";
        description = "Filesystems the exporter could not inspect.";
        expr = "sum by (instance) (node_filesystem_device_error)";
        x = 16;
        y = 9;
        w = 8;
      })
      (stat {
        id = 10;
        title = "Clock synchronized";
        description = "Kernel time synchronization required by TLS and distributed services.";
        expr = "node_timex_sync_status";
        x = 0;
        y = 13;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 11;
        title = "Unexpected read-only filesystems";
        description = "Primary filesystems that became read-only.";
        expr = "sum by (instance) (node_filesystem_readonly{mountpoint=~\"/|/persist\"})";
        x = 8;
        y = 13;
        w = 8;
      })
      (stat {
        id = 12;
        title = "WireGuard services";
        description = "Active WireGuard systemd services.";
        expr = "node_systemd_unit_state{name=~\"wg-quick-wg0.service|wg-quick@wg0.service\",state=\"active\"}";
        x = 16;
        y = 13;
        w = 8;
        steps = health;
        mappings = healthMappings;
      })
      (row {
        id = 13;
        title = "Time and thermal trends";
        y = 17;
      })
      (series {
        id = 14;
        title = "Clock offset";
        description = "Estimated local clock offset reported by timex.";
        expr = "node_timex_offset_seconds";
        x = 0;
        y = 18;
        unit = "s";
      })
      (series {
        id = 15;
        title = "Maximum positive temperature";
        description = "Highest valid hardware-monitor temperature by node.";
        expr = "max by (instance) (node_hwmon_temp_celsius > 0)";
        x = 12;
        y = 18;
        unit = "celsius";
      })
    ];
  };
  matrix = mkDashboard {
    uid = "matrix-service";
    title = "Matrix service";
    description = "Continuwuity, discovery, federation, edge/backend latency, and recovery freshness.";
    from = "now-7d";
    panels = [
      (text {
        id = 1;
        title = "Request path";
        y = 0;
        content = "Public client and federation probes traverse Cloudflare and Gloam; the backend probe reaches Continuwuity directly over WireGuard. Well-known probes validate discovery metadata.";
      })
      (row {
        id = 2;
        title = "Current state";
        y = 3;
      })
      (stat {
        id = 3;
        title = "Continuwuity";
        description = "Current homeserver systemd state.";
        expr = "node_systemd_unit_state{name=\"continuwuity.service\",state=\"active\"}";
        x = 0;
        y = 4;
        steps = health;
        mappings = healthMappings;
      })
      (stat {
        id = 4;
        title = "Matrix probe ratio";
        description = "Current success fraction across public and backend checks.";
        expr = "sum(probe_success{job=~\"blackbox-(public|backend)-matrix-.*\"}) / count(probe_success{job=~\"blackbox-(public|backend)-matrix-.*\"})";
        x = 6;
        y = 4;
        unit = "percentunit";
        min = 0;
        max = 1;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 0.99;
          }
          {
            color = "green";
            value = 1;
          }
        ];
      })
      (stat {
        id = 5;
        title = "Database backup age";
        description = "Age of the latest online database backup.";
        expr = "time() - continuwuity_backup_last_success_seconds";
        x = 12;
        y = 4;
        unit = "s";
        steps = [
          {
            color = "green";
            value = null;
          }
          {
            color = "orange";
            value = 86400;
          }
          {
            color = "red";
            value = 129600;
          }
        ];
      })
      (stat {
        id = 6;
        title = "Weekly archives";
        description = "Retained compressed database and media archives.";
        expr = "continuwuity_weekly_archive_count";
        x = 18;
        y = 4;
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "orange";
            value = 1;
          }
          {
            color = "green";
            value = 2;
          }
        ];
      })
      (stat {
        id = 7;
        title = "Matrix endpoint status";
        description = "Public, discovery, federation, support, and backend checks.";
        expr = "probe_success{job=~\"blackbox-(public|backend)-matrix-.*\"}";
        x = 0;
        y = 8;
        w = 24;
        h = 6;
        legend = "{{job}}";
        steps = health;
        mappings = healthMappings;
      })
      (row {
        id = 8;
        title = "Request path";
        y = 14;
      })
      (series {
        id = 9;
        title = "Matrix probe latency";
        description = "End-to-end public and direct-backend latency.";
        expr = "probe_duration_seconds{job=~\"blackbox-(public|backend)-matrix-.*\"}";
        x = 0;
        y = 15;
        w = 24;
        unit = "s";
        legend = "{{job}}";
      })
      (series {
        id = 10;
        title = "Matrix HTTP phases";
        description = "DNS, connect, TLS, processing, and transfer time.";
        expr = "probe_http_duration_seconds{job=~\"blackbox-public-matrix-.*\"}";
        x = 0;
        y = 22;
        unit = "s";
        legend = "{{job}} {{phase}}";
      })
      (series {
        id = 11;
        title = "Matrix availability";
        description = "Success history for every Matrix probe.";
        expr = "probe_success{job=~\"blackbox-(public|backend)-matrix-.*\"}";
        x = 12;
        y = 22;
        unit = "bool";
        min = 0;
        max = 1;
        legend = "{{job}}";
        fill = 20;
      })
      (row {
        id = 12;
        title = "Recovery history";
        y = 29;
      })
      (series {
        id = 13;
        title = "Database backup age";
        description = "Sawtooth age; resets confirm successful maintenance.";
        expr = "time() - continuwuity_backup_last_success_seconds";
        x = 0;
        y = 30;
        unit = "s";
        legend = "database backup";
      })
      (series {
        id = 14;
        title = "Weekly archive age";
        description = "Sawtooth age of the compressed database/media archive.";
        expr = "time() - continuwuity_weekly_archive_last_success_seconds";
        x = 12;
        y = 30;
        unit = "s";
        legend = "weekly archive";
      })
    ];
  };
in
  pkgs.runCommand "dusk-grafana-dashboards" {} ''
    install -d "$out"
    cp ${overview} "$out/fleet-overview.json"
    cp ${hosts} "$out/host-resources.json"
    cp ${services} "$out/service-health.json"
    cp ${storage} "$out/storage-backup.json"
    cp ${security} "$out/security-posture.json"
    cp ${matrix} "$out/matrix-service.json"
  ''
