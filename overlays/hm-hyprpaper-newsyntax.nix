# overlays/hyprpaper-toml-escape.nix
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkIf;
  cfg = config.services.hyprpaper;
in {
  options.services.hyprpaper.rawConfig = mkOption {
    type = types.nullOr types.lines;
    default = null;
    description = ''
      Raw TOML/block config for hyprpaper.
      If set, this will be written to hyprpaper.conf instead of the attribute-based settings.
      This allows use of the new hyprpaper block-syntax before the module natively supports it.
    '';
    example = lib.literalExpression ''
      wallpaper {
        monitor = *
        path = /path/to/wallpaper.png
        fit_mode = cover
      }
      splash = false
    '';
  };

  config = mkIf (cfg.enable && cfg.rawConfig != null) {
    xdg.configFile."hypr/hyprpaper.conf".text = cfg.rawConfig;
  };
}
