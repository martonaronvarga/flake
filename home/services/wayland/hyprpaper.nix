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
      preload = [", ${../../../wallpaper.png}"];
      wallpaper = [", ${../../../wallpaper.png}"];
    };
  };
}
