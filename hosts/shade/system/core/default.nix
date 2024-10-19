{ lib, config, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./security.nix
    ./users.nix
  ];
}
