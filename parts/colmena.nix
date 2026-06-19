{
  infraHosts,
  inputs,
  lib,
  self,
  ...
}: let
  deployableHosts = lib.filterAttrs (_: host: host ? deployment) infraHosts;

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
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        specialArgs = {inherit inputs self;};
      };
    }
    // lib.mapAttrs mkNode deployableHosts);
in {
  flake.colmenaHive = hive;
}
