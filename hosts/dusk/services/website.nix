{
  infraNetwork,
  inputs,
  pkgs,
  ...
}: let
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
          addr = infraNetwork.dusk.wireguard.address;
          port = infraNetwork.dusk.ports.website;
        }
      ];
      root = "${siteRoot}/share/web";
      extraConfig = ''
        access_log off;
      '';
    };
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.website
  ];

  systemd.services.nginx = {
    after = ["wg-quick-${infraNetwork.wireguard.interface}.service"];
    requires = ["wg-quick-${infraNetwork.wireguard.interface}.service"];
  };
}
