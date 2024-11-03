{
  pkgs,
  inputs,
  config,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.system}.default;

    settings = {
      splash = false;
      preload = builtins.toString ../../../wallpaper.png;
      wallpaper = ", ${builtins.toString ../../../wallpaper.png}";
    };
  };
}
