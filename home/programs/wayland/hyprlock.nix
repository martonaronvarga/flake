{
  config,
  inputs,
  pkgs,
  ...
}: let
  font_family = "Inter";
in {
  programs.hyprlock = {
    enable = true;

    package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
        enable-fingerprint = true;
      };

      background = [
        {
          monitor = "";
          path = "sceenshot";
          color = "rgba(0, 0, 0, .7)";
          blur_passes = "3";
          blur_size = "7";
          noise = "0.0117";
          contrast = "0.8916";
          brightness = "0.8125";
          vibrancy = "0.1696";
          vibrancy_darkness = "0.0";
        }
      ];

      input-field = [
        {
          monitor = "eDP-1";

          size = "300, 50";

          outline_thickness = 1;

          outer_color = "rgba(0, 0, 0, 1)";
          inner_color = "rgba(0, 0, 0, .8)";
          font_color = "rgba(0, 0, 0, .2)";

          fade_on_empty = false;
          placeholder_text = ''<span font_family="${font_family}" foreground="##00000066">Password...</span>'';

          dots_spacing = 0.2;
          dots_center = true;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          inherit font_family;
          font_size = 50;
          color = "rgba(0, 0, 0, .3)";

          position = "0, 150";

          valign = "center";
          halign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:3600000] date +'%a %b %d'";
          inherit font_family;
          font_size = 20;
          color = "rgb(0, 0, 0, .3)";

          position = "0, 50";

          valign = "center";
          halign = "center";
        }
      ];
    };
  };
}
