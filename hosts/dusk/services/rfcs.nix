{
  inputs,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) network rfcs;
  site = inputs.rfcs.packages.${pkgs.stdenv.hostPlatform.system}.site;
in
  lib.mkIf rfcs.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${rfcs.domain} = {
        listen = [
          {
            addr = network.dusk.wireguard.address;
            port = network.dusk.ports.rfcs;
          }
        ];
        root = site;
        locations."/".tryFiles = "$uri $uri/ =404";
        extraConfig = ''
          access_log syslog:server=unix:/dev/log combined;
          add_header Content-Security-Policy "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" always;
          add_header Referrer-Policy "no-referrer" always;
          add_header X-Content-Type-Options "nosniff" always;
        '';
      };
    };

    networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
      network.dusk.ports.rfcs
    ];

    systemd.services.nginx = {
      after = ["wg-quick-${network.wireguard.interface}.service"];
      requires = ["wg-quick-${network.wireguard.interface}.service"];
    };
  }
