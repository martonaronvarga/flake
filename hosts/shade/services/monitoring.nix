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
}
