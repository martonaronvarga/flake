{
  config,
  inventory,
  lib,
  ...
}: let
  inherit (inventory) domain network;
  hostName = config.networking.hostName;
  hostMetadata = {
    shade = {
      hardware = "ThinkPad X1 Carbon Gen 6 · personal workstation";
      deviceIcon = "devices.laptop";
      wireguardAddress = network.shade.wireguard.cidr;
    };
    dusk = {
      hardware = "Laptop server · services, CI and remote builds";
      deviceIcon = "devices.laptop";
      wireguardAddress = network.dusk.wireguard.cidr;
    };
    gloam = {
      hardware = "Oracle Cloud ARM edge · reverse proxy";
      deviceIcon = "devices.cloud-server";
      wireguardAddress = network.gloam.wireguard.cidr;
    };
  };
  host = hostMetadata.${hostName};
in {
  config = lib.mkIf (hostMetadata ? ${hostName}) {
    topology.self = {
      name = hostName;
      inherit (host) deviceIcon;
      hardware.info = host.hardware;
      interfaces = {
        ${network.wireguard.interface} = {
          addresses = [host.wireguardAddress];
          network = "wireguard";
          type = "wireguard";
          virtual = true;
          renderer.hidePhysicalConnections = true;
        };
        public = lib.mkIf (hostName == "gloam") {
          addresses = [network.gloam.publicIp];
          type = "ethernet";
        };
      };
      services = lib.mkMerge [
        (lib.mkIf (hostName == "shade") {
          fail2ban.hidden = true;
          remote-build-client = {
            name = "Remote build client";
            icon = "services.openssh";
            info = "ssh-ng → dusk";
          };
          shade-to-dusk.hidden = true;
        })
        (lib.mkIf (hostName == "dusk") {
          fail2ban.hidden = true;
          website = {
            name = "Personal website";
            icon = "services.nginx";
            info = "https://${domain}";
          };
          matrix = {
            name = "Matrix homeserver";
            icon = "services.matrix";
            info = "https://matrix.${domain}";
          };
          forgejo-runner = {
            name = "Forgejo Actions runner";
            icon = "services.forgejo";
            info = "Podman · nix-ci";
          };
          remote-builder = {
            name = "Remote Nix builder";
            icon = "services.openssh";
            info = "ssh-ng · 2 jobs";
          };
          nginx.hidden = true;
          postgresql.hidden = true;
        })
        (lib.mkIf (hostName == "gloam") {
          fail2ban.hidden = true;
        })
      ];
    };
  };
}
