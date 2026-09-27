{
  hostRegistry,
  inventory,
  inputs,
  lib,
  self,
  ...
}: let
  deployableHosts = lib.filterAttrs (_: host: host ? deployment) hostRegistry;

  mkNode = name: host: {
    imports = host.resolvedModules;

    networking.hostName = lib.mkDefault name;
    deployment =
      host.deployment
      // {
        tags = host.tags or [];
      };
  };

  hive = inputs.colmena.lib.makeHive ({
      meta = {
        nixpkgs = self.nixosConfigurations.dusk.pkgs;
        nodeNixpkgs = lib.mapAttrs (name: _: self.nixosConfigurations.${name}.pkgs) deployableHosts;
        specialArgs = {
          inherit inputs inventory self;
        };
      };
    }
    // lib.mapAttrs mkNode deployableHosts);
in {
  flake.colmenaHive = hive;
}
