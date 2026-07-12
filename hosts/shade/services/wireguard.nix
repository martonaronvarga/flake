{
  config,
  infraNetwork,
  pkgs,
  ...
}: {
  networking.wg-quick.interfaces.${infraNetwork.wireguard.interface} = {
    address = [infraNetwork.shade.wireguard.cidr];
    privateKeyFile = config.age.secrets.shade-wg-private-key.path;

    peers = [
      {
        publicKey = infraNetwork.gloam.wireguard.publicKey;
        endpoint = "${infraNetwork.gloam.publicIp}:${toString infraNetwork.gloam.wireguard.port}";
        allowedIPs = [infraNetwork.wireguard.subnet];
        persistentKeepalive = 25;
      }
    ];
  };

  environment.systemPackages = with pkgs; [wireguard-tools];

  systemd.services.wireguard-route-guard = {
    description = "Ensure dusk remains routed through WireGuard";
    after = ["wg-quick-${infraNetwork.wireguard.interface}.service" "network-online.target"];
    wants = ["network-online.target"];
    path = with pkgs; [
      iproute2
      systemd
    ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -euo pipefail

      route="$(ip route get ${infraNetwork.dusk.wireguard.address} || true)"
      case "$route" in
        *" dev ${infraNetwork.wireguard.interface} "*) exit 0 ;;
      esac

      systemctl restart wg-quick-${infraNetwork.wireguard.interface}.service
    '';
  };

  systemd.timers.wireguard-route-guard = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
      Unit = "wireguard-route-guard.service";
    };
  };
}
