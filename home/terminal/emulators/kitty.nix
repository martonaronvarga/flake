{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    shellIntegration.enableZshIntegration = true;
    font = {
      size = 12;
      name = "Terminess Nerd Font";
      package = pkgs.nerd-fonts.terminess-ttf;
    };

    extraConfig = ''
      hide_window_decorations titlebar-only
      adjust_column_width 0
      disable_ligatures never
      scrollback_lines 10000
      cursor_shape beam
      cursor_blink_interval 0.5
      cursor_stop_blinking_after 15.0
      placement_strategy center

      linux_display_server auto
      wayland_titlebar_color background

      allow_remote_control yes
      enable_audio_bell no
      visual_bell_duration 0.1

      window_padding_width 20 20
      confirm_os_window_close 0

      copy_on_select clipboard

      # Tab bar
      tab_bar_style fade
      tab_fade 1
      active_tab_foreground #ffffff
      active_tab_background #000000
      inactive_tab_foreground #888888
      inactive_tab_background #000000
      tab_bar_background #000000
      inactive_tab_font_style bold
      active_tab_font_style bold

      # Colors
      background #000000
      foreground #d0d0d0

      cursor #e25303

      selection_background #1a1a1a

      url_color #2a5c45

      color0 #000000

      color1 #e25303
      color2 #2a5c45
      color3 #aaaaaa
      color4 #2a5c45
      color5 #5e676e
      color6 #2a5c45
      color7 #e0e0e0
      color8 #888888
      color9 #ff6611
      color10 #33aa77
      color11 #dddddd
      color12 #33aa77
      color13 #dddddd
      color14 #33aa77
      color15 #ffffff


      map kitty_mod+t new_tab_with_cwd


    '';
  };
}
