{
  lib,
  inputs,
  withSystem ? null,
}: {
  name,
  system,
  modules ? [],
  specialArgs ? {},
}: let
  pkgs =
    if withSystem == null
    then
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }
    else withSystem system ({pkgs, ...}: pkgs);
in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system pkgs;

    specialArgs =
      {
        inherit inputs;
        inherit (inputs) self;
      }
      // specialArgs;

    modules =
      modules
      ++ [
        {
          networking.hostName = lib.mkDefault name;
        }
      ];
  }
