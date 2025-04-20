{ pkgs, config, inputs, ...}: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Terminess Nerd Font 12";
        dpi-aware = "auto";
        prompt = "~~> ";
        icons-enabled = "no";
        terminal = "kitty";
        width = "50";
        horizontal-pad = "60";
        vertical-pad = "30";
        inner-pad = "30";
        letter-spacing = "2";
      };
      colors = {
        background = "000000e6";
        text = "ffffffff";
        match = "ffffffff";
        selection = "222222ff";
        selection-match = "ffffffff";
        border = "ffffffcc";
      };
      border = {
        width = "2";
        radius = "30";
      };
      dmenu = {
        mode = "index";
      };
    };
  };
}
