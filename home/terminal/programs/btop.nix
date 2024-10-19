{pkgs, ...}: {
  programs.btop = {
    enable = true;
    settings.color_theme = "greyscale";
  };

  xdg.configFile = {
    "btop/themes/greyscale.theme".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/aristocratos/btop/refs/heads/main/themes/greyscale.theme";
      hash = "sha256-bfe8c20ebe3d180f7e0b6b2ac016c749ad3a996a";
    };
  };
}
