{ lib, config, pkgs, inputs, ...}:
{
  imports = [
   ./core
   ./disko
   ./hardware
   ./network
   ./nix
   ./programs
   ./services
  ];
}
