{
  inputs,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.topology =
      (import inputs.nix-topology {
        inherit pkgs;
        modules = [
          {inherit (self) nixosConfigurations;}
          ({config, ...}: let
            inherit (config.lib.topology) mkConnection mkDevice mkInternet;
          in {
            renderer = "elk";
            renderers.elk.overviews = {
              networks.enable = false;
              services.enable = false;
            };

            networks.wireguard = {
              name = "Private WireGuard mesh";
              cidrv4 = "10.200.200.0/24";
              icon = "interfaces.wireguard";
              style = {
                primaryColor = "#e25303";
                secondaryColor = null;
                pattern = "solid";
              };
            };

            nodes = {
              internet = mkInternet {
                connections = mkConnection "cloudflare" "edge";
              };

              cloudflare = mkDevice "Cloudflare edge" {
                deviceIcon = "devices.cloud";
                hardware.info = "DNS proxy · public ingress";
                renderer.preferredType = "card";
                connections.origin = mkConnection "gloam" "public";
                interfaces = {
                  edge.type = "ethernet";
                  origin.type = "ethernet";
                };
              };
            };
          })
        ];
      }).config.output;
  };
}
