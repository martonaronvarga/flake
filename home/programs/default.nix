{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./launchers/fuzzel.nix
    ./browsers/firefox.nix
    ./wayland
    ./office
    ./email/aerc.nix
    ./media
    ./gtk.nix
    ./office
  ];

  home.packages = with pkgs; [

  ];

}
