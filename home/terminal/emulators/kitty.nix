{ pkgs, lib, config, inputs, ...}: {
  programs.kitty = lib.mkForce {
    enable = true;
    package = pkgs.kitty;
    shellIntegration.enableZshIntegration = true;
    enableGitIntegration = true;
    font = {
      size = 14;
      name = "Terminess Nerd Font";
      package = pkgs.nerd-fonts.terminess-ttf;
    };

    extraConfig = ''
      wayland_window_title kitty
      hide_window_decorations titlebar-only
      adjust_line_height 150%
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

      initial_window_width 95c
      initial_window_height 35c
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
      foreground #383e42

      cursor #e25303

      selection_background #121212

      url_color #5e676e

      color0 #000000

      color1 #e25303
      color2 #5e676e
      color3 #5e676e
      color4 #5e676e
      color5 #5e676e
      color6 #5e676e
      color7 #5e676e
      color8 #5e676e
      color9 #73280c
      color10 #5e676e
      color11 #5e676e
      color12 #5e676e
      color13 #5e676e
      color14 #5e676e
      color15 #ffffff
      

      map kitty_mod+t new_tab_with_cwd


    '';
    
  };
}
