{
  config,
  inputs,
  inventory,
  ...
}: let
  inherit (inventory) network;
in {
  imports = [inputs.website.nixosModules.default];

  services.martonaronvarga = {
    enable = true;
    listenAddress = network.dusk.wireguard.address;
    port = network.dusk.ports.website;
    environmentFile = config.age.secrets.website-env.path;
    database.createLocally = true;
  };

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.dusk.ports.website
  ];

  systemd.services.martonaronvarga = {
    after = ["wg-quick-${network.wireguard.interface}.service"];
    requires = ["wg-quick-${network.wireguard.interface}.service"];
  };
}
