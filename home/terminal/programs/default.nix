{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./btop.nix
    ./cli.nix
    ./git.nix
    ./delta.nix
    ./ssh.nix
    ./nix.nix
    ./yazi
    ./xdg.nix
    ./hx.nix
    ./neofetch.nix
    ./tmux.nix
  ];
}
