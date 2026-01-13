{
  inputs,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./binds.nix
    ./rules.nix
    ./settings.nix
  ];

  home.packages = [
    inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
  ];

  # enable hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # set in nixos module from flake: inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
    portalPackage = null; # use the nixos module from flake: inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
      # hyprbars
      # hyprexpo
    ];

    systemd = {
      enable = false;
      variables = ["--all"];
    };
  };
}
