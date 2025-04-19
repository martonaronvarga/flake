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
   inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
  ];

  # enable hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;

    plugins = with inputs.hyprland-plugins.packages.${pkgs.system}; [
      # hyprbars
      # hyprexpo
    ];

    systemd = {
      enable = true;
      variables = ["--all"];
    };
  };
}
