_: {
  imports = [
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/gpg.nix
  ];

  hardware.graphics.enable = true;

  programs.dconf.enable = true;
  programs.nm-applet.enable = true;
}
