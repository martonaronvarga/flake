{pkgs, ...}: {
  programs.btop = {
    enable = true;
    settings.color_theme = "greyscale";
  };

  xdg.configFile = {
    "btop/themes/greyscale.theme".source = pkgs.fetchurl {
      url = "https://github.com/aristocratos/btop/blob/bfe8c20ebe3d180f7e0b6b2ac016c749ad3a996a/themes/greyscale.theme";
      hash = "sha256-8E1TXUvMg246O4aRUReWgAOiCBtrYwUenfllClqVrqk=";
    };
  };
}
