{pkgs, ...}: {
  imports = [
    ./launchers/fuzzel.nix
    ./browsers/firefox.nix
    ./wayland
    ./office
    ./email/aerc.nix
    ./media
    ./gtk.nix
  ];

  home.packages = with pkgs; [
    networkmanagerapplet
    openfortivpn
  ];
}
