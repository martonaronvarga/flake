{
  config,
  infraNetwork,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.networking.wireguardClient;
  host = infraNetwork.${cfg.hostName};
  peer = infraNetwork.${cfg.peerHostName};
  interface = infraNetwork.wireguard.interface;
in {
  options.local.networking.wireguardClient = {
    enable = lib.mkEnableOption "a WireGuard client tunnel using the shared infrastructure inventory";

    hostName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames (lib.filterAttrs (_: value: value ? wireguard) infraNetwork));
      default = config.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Inventory host whose WireGuard client address should be configured.";
    };

    peerHostName = lib.mkOption {
      type = lib.types.enum (builtins.attrNames (lib.filterAttrs (_: value: value ? wireguard) infraNetwork));
      default = "gloam";
      description = "Inventory host used as the remote WireGuard peer.";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Runtime path of the local WireGuard private key.";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Optional DNS servers installed on the wg-quick interface.";
    };

    routeGuardTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Inventory addresses that must keep routing through the WireGuard interface.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = host ? wireguard && host.wireguard ? cidr;
        message = "local.networking.wireguardClient.hostName must reference an inventory host with a WireGuard cidr.";
      }
      {
        assertion = peer ? publicIp && peer.wireguard ? publicKey && peer.wireguard ? port;
        message = "local.networking.wireguardClient.peerHostName must reference an inventory peer with endpoint metadata.";
      }
    ];

    networking.wg-quick.interfaces.${interface} = {
      address = [host.wireguard.cidr];
      inherit (cfg) privateKeyFile;
      inherit (cfg) dns;

      peers = [
        {
          publicKey = peer.wireguard.publicKey;
          endpoint = "${peer.publicIp}:${toString peer.wireguard.port}";
          allowedIPs = [infraNetwork.wireguard.subnet];
          persistentKeepalive = 25;
        }
      ];
    };

    environment.systemPackages = with pkgs; [wireguard-tools];

    systemd.services.wireguard-route-guard = lib.mkIf (cfg.routeGuardTargets != []) {
      description = "Ensure selected hosts remain routed through WireGuard";
      after = ["wg-quick-${interface}.service" "network-online.target"];
      wants = ["network-online.target"];
      path = with pkgs; [
        iproute2
        systemd
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail

        for target in ${lib.escapeShellArgs cfg.routeGuardTargets}; do
          route="$(ip route get "$target" || true)"
          case "$route" in
            *" dev ${interface} "*) ;;
            *) systemctl restart wg-quick-${interface}.service; exit 0 ;;
          esac
        done
      '';
    };

    systemd.timers.wireguard-route-guard = lib.mkIf (cfg.routeGuardTargets != []) {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "5m";
        Unit = "wireguard-route-guard.service";
      };
    };
  };
}
