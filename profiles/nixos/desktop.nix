_: {
  imports = [
    ../../modules/nixos/gpg.nix
    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/pipewire.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/spotify.nix
    ../../modules/nixos/zsh.nix
  ];

  hardware.graphics.enable = true;

  programs.dconf.enable = true;
}
