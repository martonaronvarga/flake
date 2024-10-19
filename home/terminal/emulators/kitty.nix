{ pkgs, lib, config, imputs, ...}: {
  programs.kitty = {
    enable = true;
    font = {
      size = 14;
      name = "Terminus (TTF) Bold";
      package = pkgs.terminus_font_ttf;
    };

    settings = {
      scrollback_lines = 10000;
      placement_strategy = "center";

      linux_display_server = "wayland";
      wayland_titlebar_color = "background";

      allow_remote_control = "yes";
      enable_audio_bell = "no";
      visual_bell_duration = "0.1";

      initial_window_width = "95c";
      initial_window_height = "35c";
      window_padding_width = "20";
      confirm_os_window_close = "0";

      copy_on_select = "clipboard";
      
      # Tab bar

      tab_bar_style = "fade";
      tab_fade = "1";
      active_tab_foreground = "#ffffff";
      active_tab_background = "#000000";
      inactive_tab_foreground = "#888888";
      inactive_tab_background = "#000000";
      tab_bar_background = "#000000";
      inactive_tab_font_style = "bold";
      active_tab_font_style = "bold";

      # Colors

      background = "#000000";
      foreground = "#ffffff";

      cursor = "#ffffff";

      selection_background = "#444444";
      selection_foreground = "#ffffff";

      url_color = "#888888";

      color0 = "#000000";
      color8 = "#555555";

      color1 = "#ff5555";
      color9 = "#ff6e6e";

      color2 = "#55ff55W";
      color10 = "#6eff6e";

      color3 = "#ffff55";
      color11 = "#ffff6e";

      color4 = "#5555ff";
      color12 = "#6e6eff";

      color5  = "#ff55ff";
      color13 = "#ff6eff";

      color6  = "#55ffff";
      color14 = "#6effff";

      color7  = "#bbbbbb";
      color15 = "#ffffff";


      map = "kitty_mod+t new_tab_with_cwd";
    };

  };
}
