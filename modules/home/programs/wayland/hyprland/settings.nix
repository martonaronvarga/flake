{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  pointer = config.home.pointerCursor;
  cursorName = "catppuccin-mocha-flamingo-cursors";
in {
  wayland.windowManager.hyprland.settings = {
    monitor = {
      output = "eDP-1";
      mode = "preferred";
      position = "auto";
      scale = 1.25;
    };
    env = [
      {_args = ["HYPRCURSOR_THEME" "${cursorName}"];}
      {_args = ["HYPRCURSOR_SIZE" "${toString pointer.size}"];}
      {_args = ["XCURSOR_THEME" "${cursorName}"];}
      {_args = ["XCURSOR_SIZE" "${toString pointer.size}"];}
      {_args = ["XDG_CURRENT_DESKTOP" "Hyprland"];}
      {_args = ["XDG_SESSION_TYPE" "wayland"];}
    ];

    on = {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd("uwsm finalize")
            hl.exec_cmd("hyprctl setcursor ${cursorName} ${toString pointer.size}")
            hl.exec_cmd("blueman-applet")
          end
        '')
      ];
    };

    config = {
      general = {
        layout = "dwindle";
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        col.active_border = "rgba(b0b0b050)";
        col.inactive_border = "rgba(00000066)";
        float_gaps = 0;
        no_focus_fallback = true;

        allow_tearing = true;
        resize_on_border = true;
      };

      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.3;

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
          render_power = 4;
          color = "rgba(b0b0b050)";
          color_inactive = "rgba(000000FF)";
        };
      };

      animations = {
        enabled = true;
      };

      group = {
        auto_group = false;
        drag_into_group = 0;
        merge_groups_on_drag = false;
        merge_groups_on_groupbar = false;
        merge_floated_into_tiled_on_groupbar = false;
        group_on_movetoworkspace = false;
        groupbar = {
          font_size = 10;
          gradients = false;
          text_color = "rgb(FFFFFF)";
        };

        col.border_active = "rgba(b0b0b050)";
        col.border_inactive = "rgba(000000FF)";
      };

      input = {
        kb_layout = "us,hu";
        kb_options = "caps:escape,grp:shifts_toggle";
        repeat_rate = 50;
        repeat_delay = 240;

        # focus change on cursor move
        follow_mouse = 1;
        accel_profile = "flat";
        touchpad.scroll_factor = 0.5;
        touchpad.natural_scroll = true;
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
        font_family = "Terminess Nerd Font";
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = true;
        allow_session_lock_restore = true;
        middle_click_paste = false;

        # enable variable refresh rate (effective depending on hardware)
        vrr = 1;
      };

      # touchpad gestures
      gestures = {
        workspace_swipe_forever = true;
        workspace_swipe_min_speed_to_force = 5;
      };

      xwayland = {
        force_zero_scaling = true;
      };

      render = {
        direct_scanout = 1;
      };

      ecosystem = {
        enforce_permissions = true;
        no_update_news = true;
        no_donation_nag = true;
      };

      debug.disable_logs = false;
    };

    curve = {
      _args = [
        "overshot"
        {
          type = "bezier";
          points = [[0.13 0.99] [0.29 1.1]];
        }
      ];
    };
    animation = [
      {
        leaf = "border";
        enabled = true;
        speed = 10;
        bezier = "default";
      }
      {
        leaf = "borderangle";
        enabled = true;
        speed = 8;
        bezier = "default";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 10;
        bezier = "default";
      }
      {
        leaf = "windows";
        enabled = true;
        speed = 4;
        bezier = "overshot";
        style = "popin";
      }
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 7;
        bezier = "default";
        style = "popin 80%";
      }
      {
        leaf = "workspaces";
        enabled = true;
        speed = 6;
        bezier = "overshot";
        style = "slide";
      }
    ];
    gesture = [
      {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      }
      {
        fingers = 3;
        direction = "up";
        scale = 1.5;
        action = "fullscreen";
      }
      {
        fingers = 3;
        direction = "swipe";
        mods = "SUPER";
        action = "move";
      }
      {
        fingers = 2;
        direction = "pinchin";
        mods = "SUPER";
        action = "float";
        mode = "tile";
      }
      {
        fingers = 2;
        direction = "pinchout";
        mods = "SUPER";
        action = "float";
        mode = "float";
      }
      {
        fingers = 4;
        direction = "left";
        action = lib.generators.mkLuaInline ''function() hl.dispatch(hl.dsp.window.move({ monitor = "-1" })) end'';
      }
      {
        fingers = 4;
        direction = "right";
        action = lib.generators.mkLuaInline ''function() hl.dispatch(hl.dsp.window.move({ monitor = "+1" })) end'';
      }
    ];
    permission = map (path: {_args = [(lib.escapeRegex path) "screencopy" "allow"];}) [
      "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland}/libexec/.xdg-desktop-portal-hyprland-wrapped"
      (lib.getExe pkgs.grim)
      (lib.getExe config.programs.hyprlock.package)
      "${pkgs.wluma}/bin/.wluma-wrapped"
      (lib.getExe pkgs.wl-screenrec)
    ];
  };
}
