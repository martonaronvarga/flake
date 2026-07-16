{inventory, ...}: let
  inherit (inventory) network;
in {
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = network.shade.wireguard.address;
    enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
    port = network.shade.ports.nodeExporter;
  };

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.shade.ports.nodeExporter
  ];

  systemd.services.prometheus-node-exporter = {
    after = ["wg-quick-${network.wireguard.interface}.service"];
    requires = ["wg-quick-${network.wireguard.interface}.service"];
  };
}
