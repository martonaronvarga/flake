{infraNetwork, ...}: {
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = infraNetwork.shade.wireguard.address;
    enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
    port = infraNetwork.shade.ports.nodeExporter;
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.shade.ports.nodeExporter
  ];

  systemd.services.prometheus-node-exporter = {
    after = ["wg-quick-${infraNetwork.wireguard.interface}.service"];
    requires = ["wg-quick-${infraNetwork.wireguard.interface}.service"];
  };
}
