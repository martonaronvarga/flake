{pkgs, ...}: {
  programs.btop = {
    enable = true;
    settings.color_theme = "greyscale";
  };

  xdg.configFile = {
    "btop/themes/greyscale.theme".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/aristocratos/btop/refs/heads/main/themes/greyscale.theme";
      sha256 = "1adfjmd0lrgrklg0aqvb3c4a40w0jqbm34c67cx6x0yc9dfm6kgh";
    };
  };
}
