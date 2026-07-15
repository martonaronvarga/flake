{
  config,
  infraNetwork,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.services.duskWireGuard;
in {
  options.local.services.duskWireGuard = {
    enable = lib.mkEnableOption "dusk WireGuard client tunnel to gloam";

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/agenix/dusk-wg-private-key";
      description = "Runtime path of the Dusk WireGuard private key.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wg-quick.interfaces.${infraNetwork.wireguard.interface} = {
      address = [infraNetwork.dusk.wireguard.cidr];
      inherit (cfg) privateKeyFile;
      dns = ["1.1.1.1" "9.9.9.9"];

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
  };
}
