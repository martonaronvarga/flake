{
  config,
  inputs,
  pkgs,
  ...
}: let
  font_family = "Terminess Nerd Font";
in {
  programs.hyprlock = {
    enable = true;

    package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
        enable_fingerprint = true;
        no_fade_in = false;
        no_fade_out = false;
        grace = 5;
      };

      background = [
        {
          monitor = "";
          path = "sceenshot";
          color = "rgba(0, 0, 0, .4)";
          blur_passes = 3;
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8125;
          vibrancy = 0.1696;
          vibrancy_darkness = "0.0";
        }
      ];

      input-field = [
        {
          monitor = "";

          size = "300, 50";

          outline_thickness = 3;

          outer_color = "rgba(25, 25, 25, 1)";
          inner_color = "rgba(0, 0, 0, .8)";
          font_color = "rgba(255, 255, 255, .8)";


          fade_on_empty = false;
          placeholder_text = "<span foreground='#ffffff66'>Password...</span>";

          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;

          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] date +'%H:%M'";
          inherit font_family;
          font_size = 50;
          color = "rgba(255, 255, 255, .3)";

          position = "0, 150";

          valign = "center";
          halign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:3600000] date +'%a %b %d'";
          inherit font_family;
          font_size = 20;
          color = "rgb(255, 255, 255, 0.6)";

          position = "0, 50";

          valign = "center";
          halign = "center";
        }
        {
          text = "cmd[update:30000] cat /sys/class/power_supply/BAT0/capacity";
          position = "0, -150";
        }
      ];
    };
  };
}
