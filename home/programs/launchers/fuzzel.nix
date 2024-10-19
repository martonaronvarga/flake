{ pkgs, config, inputs, ...}: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Noto Sans";
        dpi-aware = "auto";
        prompt = "󱄅";
        icons-enabled = "no";
        terminal = "kitty";
        width = "50";
        horizontal-pad = "60";
        vertical-pad = "30";
        inner-pad = "30";
        letter-spacing = "2";
      };
      colors = {
        background = "3137487f";
        text = "ffffffff";
        match = "FB958Bdd";
        selection = "e7e7e7e7";
        selection-match = "FB958Bdd";
        border = "3137487f";
      };
      border = {
        width = "0.1";
        radius = "30";
      };
      dmenu = {
        mode = "index";
      };
    };
  };
}
