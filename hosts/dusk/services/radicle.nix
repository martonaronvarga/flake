{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) network radicle;
  explorer = pkgs.radicle-explorer.withConfig {
    preferredSeeds = [
      {
        # Keep Explorer API requests same-origin. Gloam routes /api/ on the
        # Explorer hostname to radicle-httpd and all other paths here.
        hostname = radicle.webDomain;
        port = 443;
        scheme = "https";
      }
    ];
  };
in
  lib.mkIf radicle.enable {
    services.radicle = {
      enable = true;
      package = pkgs.radicle-node;
      privateKey = config.age.secrets.radicle-seed-key.path;
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMOSqr5c2XLD4CxJ56/4D2zuaS94X0z0oLBCWuUcq7D";
      node = {
        listenAddress = network.dusk.wireguard.address;
        listenPort = network.dusk.ports.radicleNode;
      };
      settings.node = {
        alias = radicle.seedDomain;
        externalAddresses = ["${radicle.seedDomain}:${toString network.dusk.ports.radicleNode}"];
        seedingPolicy = {
          default = "block";
          scope = "all";
        };
      };
      httpd = {
        enable = true;
        package = pkgs.radicle-httpd;
        listenAddress = network.dusk.wireguard.address;
        listenPort = network.dusk.ports.radicleHttpd;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${radicle.webDomain} = {
        listen = [
          {
            addr = network.dusk.wireguard.address;
            port = network.dusk.ports.radicleExplorer;
          }
        ];
        root = explorer;
        locations."/".tryFiles = "$uri $uri/ /index.html";
        extraConfig = ''
          access_log syslog:server=unix:/dev/log combined;
        '';
      };
    };

    networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
      network.dusk.ports.radicleNode
      network.dusk.ports.radicleHttpd
      network.dusk.ports.radicleExplorer
    ];

    systemd.services = {
      radicle-node = {
        after = ["wg-quick-${network.wireguard.interface}.service"];
        requires = ["wg-quick-${network.wireguard.interface}.service"];
      };
      radicle-httpd = {
        after = ["radicle-node.service" "wg-quick-${network.wireguard.interface}.service"];
        requires = ["radicle-node.service" "wg-quick-${network.wireguard.interface}.service"];
      };
    };
  }
