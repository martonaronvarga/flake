{lib, ...}: let
  mkRegex = list: "^(${lib.concatStringsSep "|" list})$";
  layerRegex = list: {namespace = mkRegex list;};

  classRegex = list: {class = mkRegex list;};

  lowopacity = [
    "bar"
    "calendar"
    "notifications"
    "system-menu"
  ];

  highopacity = [
    "fuzzel"
    "obsidian"
    "spotify"
    "osd"
    "logout_dialog"
  ];

  blurred = lowopacity ++ highopacity;
in {
  wayland.windowManager.hyprland.settings = {
    layer_rule = [
      {
        match = layerRegex blurred;
        blur = true;
      }

      # bar wants xray blur
      {
        match = layerRegex ["bar"];
        xray = true;
      }

      # higher alpha threshold: only blur less transparent areas
      {
        match = layerRegex (highopacity ++ ["music"]);
        ignore_alpha = 0.5;
      }

      # lower alpha threshold for translucent shell layers.
      {
        match = layerRegex lowopacity;
        ignore_alpha = 0.2;
      }

      # notifications feel better without compositor animation fighting notification animation
      {
        match = layerRegex ["notifications"];
        no_anim = true;
      }
    ];

    window_rule = [
      # Common modal dialogs.
      {
        match = {modal = true;};
        float = true;
      }
      {
        match = {modal = true;};
        center = true;
      }
      {
        match = {modal = true;};
        dim_around = true;
      }

      # Generic floating utility windows.
      {
        match = classRegex [
          "blueman-manager"
          "Bluetooth-Devices"
          "org.pulseaudio.pavucontrol"
          "pavucontrol"
          "termfilechooser"
          "wallpaper-selector"
          "waybar-selector"
        ];
        float = true;
      }

      {
        match = classRegex [
          "blueman-manager"
          "Bluetooth-Devices"
          "org.pulseaudio.pavucontrol"
          "pavucontrol"
          "termfilechooser"
          "wallpaper-selector"
          "waybar-selector"
        ];
        center = true;
      }

      {
        match = {class = "^(wallpaper-selector)$";};
        size = "800 520";
      }
      {
        match = {class = "^(waybar-selector)$";};
        size = "460 220";
      }

      {
        match = classRegex [
          "termfilechooser"
          "hyprpolkitagent"
          "polkit-gnome-authentication-agent-1"
        ];
        dim_around = true;
      }

      # Pinentry focus fix.
      {
        match = {class = "^(pinentry-.*)$";};
        stay_focused = true;
      }
      {
        match = {class = "^(pinentry-.*)$";};
        center = true;
      }
      {
        match = {class = "^(pinentry-.*)$";};
        float = true;
      }
      {
        match = {class = "^(pinentry-.*)$";};
        size = "500 160";
      }
      {
        match = {class = "^(pinentry-.*)$";};
        dim_around = true;
      }

      # Static effects are title-sensitive, so include likely initial titles too.
      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(File Upload|Open File|Save File|Choose File|Select File)$";
        };
        float = true;
      }
      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(File Upload|Open File|Save File|Choose File|Select File)$";
        };
        center = true;
      }
      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(File Upload|Open File|Save File|Choose File|Select File)$";
        };
        size = "900 650";
      }
      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(File Upload|Open File|Save File|Choose File|Select File)$";
        };
        max_size = "1100 800";
      }
      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(File Upload|Open File|Save File|Choose File|Select File)$";
        };
        dim_around = true;
      }

      # Keep Firefox visually solid even when blur/alpha rules are active elsewhere.
      {
        match = {class = "^(firefox)$";};
        opaque = true;
      }
      {
        match = {class = "^(firefox)$";};
        no_blur = true;
      }

      # Portal file chooser itself.
      {
        match = {class = "^(termfilechooser)$";};
        size = "900 650";
      }
      {
        match = {class = "^(termfilechooser)$";};
        max_size = "1100 800";
      }

      # Launchers / panels / small utilities
      {
        match = {class = "^(fuzzel)$";};
        float = true;
      }
      {
        match = {class = "^(fuzzel)$";};
        center = true;
      }
      {
        match = {class = "^(fuzzel)$";};
        no_anim = true;
      }

      # Media viewers
      {
        match = {class = "^(feh)$";};
        float = true;
      }
      {
        match = {class = "^(feh)$";};
        center = true;
      }
      {
        match = {class = "^(feh)$";};
        size = "monitor_w*0.8 monitor_h*0.8";
      }
      {
        match = {class = "^(feh)$";};
        keep_aspect_ratio = true;
      }
      {
        match = {class = "^(feh)$";};
        opaque = true;
      }
      {
        match = {class = "^(feh)$";};
        no_blur = true;
      }
      {
        match = {class = "^(feh)$";};
        rounding = 0;
      }

      # Video players.
      {
        match = {class = "^(mpv|vlc)$";};
        idle_inhibit = "focus";
      }
      {
        match = {class = "^(mpv|vlc)$";};
        content = "video";
      }

      {
        match = {class = "^(Spotify)$";};
        workspace = "9 silent";
      }
      {
        match = {title = "^(Spotify( Premium)?)$";};
        workspace = "9 silent";
      }

      # PiP
      {
        match = {title = "^(Picture-in-Picture)$";};
        float = true;
      }
      {
        match = {title = "^(Picture-in-Picture)$";};
        pin = true;
      }
      {
        match = {title = "^(Picture-in-Picture)$";};
        size = "480 270";
      }
      {
        match = {title = "^(Picture-in-Picture)$";};
        move = "monitor_w-500 monitor_h-310";
      }
      {
        match = {title = "^(Picture-in-Picture)$";};
        keep_aspect_ratio = true;
      }
      {
        match = {title = "^(Picture-in-Picture)$";};
        no_shadow = true;
      }

      # Screen sharing indicators
      {
        match = {title = "^(Firefox — Sharing Indicator)$";};
        workspace = "special silent";
      }
      {
        match = {title = "^(Zen — Sharing Indicator)$";};
        workspace = "special silent";
      }
      {
        match = {title = "^(.*is sharing (your screen|a window)\\.)$";};
        workspace = "special silent";
      }
      {
        match = {title = "^(.*is sharing (your screen|a window)\\.)$";};
        no_focus = true;
      }

      {
        match = {
          class = "^(firefox|zen|zen-browser)$";
          title = "^(.*YouTube.*)$";
        };
        idle_inhibit = "focus";
      }
      {
        match = {class = "^(firefox|zen|zen-browser)$";};
        idle_inhibit = "fullscreen";
      }

      # XWayland normalization
      {
        match = {xwayland = true;};
        rounding = 0;
      }
      {
        match = {
          xwayland = true;
          class = "^$";
          title = "^$";
        };
        no_focus = true;
      }
      {
        match = {
          xwayland = true;
          class = "^$";
          title = "^$";
        };
        no_anim = true;
      }
    ];
  };
}
