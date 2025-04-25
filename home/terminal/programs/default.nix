{ pkgs, config, lib, ...}: {
  imports = [
    ./btop.nix
    ./cli.nix
    ./git.nix
    ./nix.nix
    ./yazi
    ./xdg.nix
    ./hx.nix
  ];
}
