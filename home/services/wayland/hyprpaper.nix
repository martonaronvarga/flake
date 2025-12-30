{
  pkgs,
  inputs,
  config,
  ...
}: let
  wallpaper = builtins.path {
    path = ../../../wallpaper.png;
    name = "wallpaper";
  };
in {
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      splash = false;
      preload = ["${wallpaper}"];
      wallpaper = ", ${wallpaper}";
    };
  };
}
