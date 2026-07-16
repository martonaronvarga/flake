{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.networking.wireguardClient;
in {
  options.local.networking.wireguardClient = {
    enable = lib.mkEnableOption "a WireGuard client tunnel";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };

    addresses = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      description = "Local WireGuard interface addresses in CIDR notation.";
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

    peers = lib.mkOption {
      type = lib.types.nonEmptyListOf (lib.types.submodule {
        options = {
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Remote peer public key.";
          };

          endpoint = lib.mkOption {
            type = lib.types.str;
            description = "Remote peer endpoint in host:port form.";
          };

          allowedIPs = lib.mkOption {
            type = lib.types.nonEmptyListOf lib.types.str;
            description = "Allowed IP ranges routed through this peer.";
          };

          persistentKeepalive = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Optional persistent keepalive interval in seconds.";
          };
        };
      });
      description = "WireGuard peers for this client.";
    };

    routeGuard = {
      targets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Addresses that must keep routing through the WireGuard interface.";
      };

      onBootSec = lib.mkOption {
        type = lib.types.str;
        default = "2m";
        description = "Initial route guard timer delay.";
      };

      onUnitActiveSec = lib.mkOption {
        type = lib.types.str;
        default = "5m";
        description = "Route guard repeat interval.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wg-quick.interfaces.${cfg.interface} = {
      address = cfg.addresses;
      inherit (cfg) privateKeyFile;
      inherit (cfg) dns;
      peers = map (peer:
        {
          inherit (peer) publicKey endpoint allowedIPs;
        }
        // lib.optionalAttrs (peer.persistentKeepalive != null) {
          inherit (peer) persistentKeepalive;
        })
      cfg.peers;
    };

    environment.systemPackages = with pkgs; [wireguard-tools];

    systemd.services.wireguard-route-guard = lib.mkIf (cfg.routeGuard.targets != []) {
      description = "Ensure selected hosts remain routed through WireGuard";
      after = ["wg-quick-${cfg.interface}.service" "network-online.target"];
      wants = ["network-online.target"];
      path = with pkgs; [
        iproute2
        systemd
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail

        for target in ${lib.escapeShellArgs cfg.routeGuard.targets}; do
          route="$(ip route get "$target" || true)"
          case "$route" in
            *" dev ${cfg.interface} "*) ;;
            *) systemctl restart wg-quick-${cfg.interface}.service; exit 0 ;;
          esac
        done
      '';
    };

    systemd.timers.wireguard-route-guard = lib.mkIf (cfg.routeGuard.targets != []) {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = cfg.routeGuard.onBootSec;
        OnUnitActiveSec = cfg.routeGuard.onUnitActiveSec;
        Unit = "wireguard-route-guard.service";
      };
    };
  };
}
