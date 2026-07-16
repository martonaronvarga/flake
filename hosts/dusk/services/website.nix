{
  inventory,
  inputs,
  pkgs,
  ...
}: let
  inherit (inventory) network;
  siteRoot = inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.site;
in {
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts."martonaronvarga.dev" = {
      listen = [
        {
          addr = network.dusk.wireguard.address;
          port = network.dusk.ports.website;
        }
      ];
      root = "${siteRoot}/share/web";
      extraConfig = ''
        access_log off;
      '';
    };
  };

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.dusk.ports.website
  ];

  systemd.services.nginx = {
    after = ["wg-quick-${network.wireguard.interface}.service"];
    requires = ["wg-quick-${network.wireguard.interface}.service"];
  };
}
