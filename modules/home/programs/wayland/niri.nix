{
  config,
  lib,
  pkgs,
  ...
}: let
  cursor = config.home.pointerCursor;
  cursorName = "catppuccin-mocha-flamingo-cursors";
  spawn = command: ''spawn "${command}"'';
  spawnArgs = args: "spawn ${lib.concatMapStringsSep " " (arg: ''"${arg}"'') args}";
  playerctl = lib.getExe pkgs.playerctl;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brillo = lib.getExe pkgs.brillo;
in {
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us,hu"
                options "caps:escape,grp:shifts_toggle"
            }
            repeat-delay 240
            repeat-rate 50
        }
        touchpad {
            tap
            natural-scroll
            accel-profile "flat"
            scroll-factor 0.5
        }
        mouse {
            accel-profile "flat"
        }
        focus-follows-mouse max-scroll-amount="0%"
    }

    output "eDP-1" {
        scale 1.25
    }

    layout {
        gaps 5
        struts {
            left 10
            right 10
            top 10
            bottom 10
        }
        center-focused-column "never"
        default-column-width { proportion 0.5; }
        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
            proportion 1.0
        }
        focus-ring {
            width 2
            active-gradient from="#000000" to="#808080" angle=45
            inactive-color "#00000066"
        }
        border { off; }
        shadow {
            on
            softness 24
            spread 2
            offset x=0 y=5
            color "#000000ff"
        }
    }

    prefer-no-csd
    screenshot-path "~/pictures/screenshots/%Y-%m-%dT%H:%M:%S.png"

    cursor {
        xcursor-theme "${cursorName}"
        xcursor-size ${toString cursor.size}
        hide-when-typing
    }

    xwayland-satellite {
        path "${lib.getExe pkgs.xwayland-satellite}"
    }

    environment {
        XCURSOR_THEME "${cursorName}"
        XCURSOR_SIZE "${toString cursor.size}"
        NIXOS_OZONE_WL "1"
        MOZ_ENABLE_WAYLAND "1"
        _JAVA_AWT_WM_NONREPARENTING "1"
    }

    workspace "music"

    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    window-rule {
        match app-id=r#"^(blueman-manager|org.pulseaudio.pavucontrol|pavucontrol|termfilechooser|wallpaper-selector|waybar-selector)$"#
        open-floating true
    }
    window-rule {
        match app-id=r#"^wallpaper-selector$"#
        default-column-width { fixed 800; }
        default-window-height { fixed 520; }
    }
    window-rule {
        match app-id=r#"^waybar-selector$"#
        default-column-width { fixed 460; }
        default-window-height { fixed 220; }
    }
    window-rule {
        match app-id=r#"^(Spotify|spotify)$"#
        open-on-workspace "music"
    }
    window-rule {
        match title=r#"^Picture-in-Picture$"#
        open-floating true
        default-floating-position x=20 y=20 relative-to="bottom-right"
        default-column-width { fixed 480; }
        default-window-height { fixed 270; }
    }
    window-rule {
        match app-id=r#"^(mpv|vlc)$"#
        block-out-from "screen-capture"
    }

    binds {
        Mod+Shift+E { quit; }
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Shift+F { maximize-column; }
        Mod+T { toggle-window-floating; }
        Mod+G { toggle-column-tabbed-display; }

        Mod+Return { ${spawnArgs ["uwsm" "app" "--" "kitty"]}; }
        Mod+B { ${spawn "firefox"}; }
        Mod+D { ${spawn "fuzzel"}; }
        Mod+Escape { ${spawn "wlogout"}; }
        Mod+L { ${spawnArgs ["loginctl" "lock-session"]}; }
        Mod+Shift+W { ${spawn "select-wallpaper"}; }
        Mod+Shift+B { ${spawn "select-waybar"}; }

        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Down { move-window-down; }
        Mod+Tab { focus-window-or-workspace-down; }

        Mod+BracketLeft { focus-workspace-up; }
        Mod+BracketRight { focus-workspace-down; }
        Mod+Ctrl+BracketLeft { move-column-to-workspace-up; }
        Mod+Ctrl+BracketRight { move-column-to-workspace-down; }
        Mod+Shift+BracketLeft { focus-monitor-left; }
        Mod+Shift+BracketRight { focus-monitor-right; }
        Mod+Shift+Alt+BracketLeft { move-workspace-to-monitor-left; }
        Mod+Shift+Alt+BracketRight { move-workspace-to-monitor-right; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
        Mod+Shift+R { screenshot; }

        XF86AudioPlay allow-when-locked=true { ${spawnArgs [playerctl "play-pause"]}; }
        XF86AudioPrev allow-when-locked=true { ${spawnArgs [playerctl "previous"]}; }
        XF86AudioNext allow-when-locked=true { ${spawnArgs [playerctl "next"]}; }
        XF86AudioMute allow-when-locked=true { ${spawnArgs [wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"]}; }
        XF86AudioMicMute allow-when-locked=true { ${spawnArgs [wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"]}; }
        XF86AudioRaiseVolume allow-when-locked=true { ${spawnArgs [wpctl "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "6%+"]}; }
        XF86AudioLowerVolume allow-when-locked=true { ${spawnArgs [wpctl "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "6%-"]}; }
        XF86MonBrightnessUp allow-when-locked=true { ${spawnArgs [brillo "-q" "-u" "300000" "-A" "5"]}; }
        XF86MonBrightnessDown allow-when-locked=true { ${spawnArgs [brillo "-q" "-u" "300000" "-U" "5"]}; }
    }
  '';
}
