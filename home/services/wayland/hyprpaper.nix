{
  pkgs,
  inputs,
  ...
}: let
  wallpaper = builtins.path {
    path = ../../../wallpaper.png;
    name = "wallpaper";
  };
in {
  # imports = [../../../overlays/hm-hyprpaper-newsyntax.nix];
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper;

    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "${wallpaper}";
          fit_mode = "cover";
        }
      ];
    };
  };
}
