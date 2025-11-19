{config, ...}: let
  pointer = config.home.pointerCursor;
  cursorName = "catppuccin-mocha-flamingo-cursors";
in {
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    monitor = "eDP-1, preferred, auto, 1.25";
    env = [
      "HYPRCURSOR_THEME,${cursorName}"
      "HYPRCURSOR_SIZE,${toString pointer.size}"
      "XCURSOR_THEME, ${cursorName}"
      "XCURSOR_SIZE, ${toString pointer.size}"
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
    ];

    exec-once = [
      "hyprctl setcursor ${cursorName} ${toString pointer.size}"
      "blueman-applet"
      "dunst"
      "waybar"
      "hyprlock"
    ];

    general = {
      layout = "dwindle";
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      "col.active_border" = "rgba(000000ff) rgba(808080ee) 45deg";
      "col.inactive_border" = "rgba(00000066)";
      no_border_on_floating = true;
      no_focus_fallback = true;
      resize_on_border = true;
    };

    decoration = {
      rounding = 12;
      active_opacity = 1.0;
      dim_inactive = true;
      dim_strength = 0.4;

      blur = {
        enabled = true;
        size = 2;
        passes = 1;
        brightness = 1.0;
        vibrancy = 1.0;
        popups = true;
        popups_ignorealpha = 0.2;
      };

      shadow = {
        enabled = true;
        range = 12;
        render_power = 6;
        color = "rgba(ffffff50)";
        color_inactive = "rgba(000000FF)";
      };
    };

    animations = {
      enabled = true;
      bezier = "overshot, 0.13, 0.99, 0.29, 1.1";
      animation = [
        "border, 1, 10, default"
        "borderangle, 1, 8, default"
        "fade, 1, 10, default"
        "windows, 1, 4, overshot, popin"
        "windowsOut, 1, 7, default, popin 80%"
        "workspaces, 1, 6, overshot, slide"
      ];
    };

    group = {
      groupbar = {
        font_size = 10;
        gradients = false;
        text_color = "rgb(FFFFFF)";
      };

      "col.border_active" = "rgba(FFFFFF25)";
      "col.border_inactive" = "rgba(000000FF)";
    };

    input = {
      kb_layout = "us";
      kb_options = "caps:escape";
      repeat_rate = 50;
      repeat_delay = 240;

      # focus change on cursor move
      follow_mouse = 1;
      accel_profile = "flat";
      touchpad.scroll_factor = 0.5;
      touchpad.natural_scroll = true;
    };

    dwindle = {
      # keep floating dimensions while tiling
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      force_default_wallpaper = 0;
      disable_hyprland_logo = true;

      # enable variable refresh rate (effective depending on hardware)
      vrr = 1;
    };

    # touchpad gestures
    gestures = {
      workspace_swipe = true;
      workspace_swipe_forever = true;
      workspace_swipe_min_speed_to_force = 5;
    };
  };
}
