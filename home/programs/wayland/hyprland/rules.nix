{lib, ...}: {
  wayland.windowManager.hyprland.settings = {
    # layer rules
    layerrule = let
      toRegex = list: let
        elements = lib.concatStringsSep "|" list;
      in "match:namespace ^(${elements})$";

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

      blurred = lib.concatLists [
        lowopacity
        highopacity
      ];
    in [
      "${toRegex blurred}, blur on"
      "${toRegex ["bar"]}, xray on"
      "${toRegex (highopacity ++ ["music"])}, ignore_alpha 0.5"
      "${toRegex lowopacity}, ignore_alpha 0.2"
      "${toRegex ["notifications"]}, no_anim on"
    ];

    # window rules
    windowrule = [
      "match:class (Zotero), float on"
      "match:class Bluetooth-Devices, float on"
      "match:class fuzzel, float on"
      "match:class ^(blueman-manager)$, float on"
      "match:class ^(xdg-desktop-portal-gtk)$, float on"
      "match:title pavucontrol, float on"
      # make Firefox/Zen PiP window floating and sticky
      "match:title ^(Picture-in-Picture)$, float on"
      "match:title ^(Picture-in-Picture)$, pin on"

      # throw sharing indicators away
      "match:title ^(Firefox — Sharing Indicator)$, workspace special silent"
      "match:title ^(Zen — Sharing Indicator)$, workspace special silent"
      "match:title ^(.*is sharing (your screen|a window)\.)$, workspace special silent"

      # start spotify in ws9
      "match:title ^(Spotify( Premium)?)$, workspace 9 silent"

      # idle inhibit while watching videos
      "match:class ^(mpv|.+exe|vlc)$, idle_inhibit focus"
      "match:class ^(firefox)$, match:title ^(.*YouTube.*)$, idle_inhibit focus"
      "match:class ^(firefox)$, idle_inhibit fullscreen"

      "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"
      "match:class ^(hyprpolkitagent)$, dim_around on"
      "match:class ^(polkit-gnome-authentication-agent-1)$, dim_around on"
      "match:class ^(firefox)$, match:title ^(File Upload)$, dim_around on"

      # fix xwayland apps
      "match:xwayland true, rounding 0"
      "match:title ^(.*is sharing (your screen|a window)\.)$, no_focus on"

      "match:class (pinentry-)(.*), stay_focused on" # Fix pinentry losing focus
    ];
  };
}
