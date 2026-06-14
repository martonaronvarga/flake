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
        ];
      }).config.output;
  };
}
