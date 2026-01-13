{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 10;
        margin-left = 10;
        margin-right = 10;
        margin-top = 5;
        margin-bottom = 0;
        spacing = 10;
        modules-left = ["cpu" "memory" "hyprland/workspaces"];
        modules-center = ["custom/media"];
        modules-right = ["tray" "custom/keyboard" "network" "backlight" "battery" "pulseaudio" "clock" "custom/quit"];

        "hyprland/workspaces" = {
          format = "{icon}";
          all-outputs = true;
          on-click = "activate";
          "format-icons" = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            urgent = " ";
            focused = " ";
            default = " ";
          };
        };

        tray = {
          spacing = 8;
          icon-size = 7;
          icon-limit = 5;
          scroll = true;
        };

        cpu = {
          format = "  {usage}%";
          max-length = 10;
          interval = 1;
        };

        memory = {
          format = "󰇂  {used:0.1f}G";
          max-length = 10;
          interval = 1;
        };

        backlight = {
          device = "DP-1";
          format = "{icon} {percent}%";
          format-icons = ["" "" "" "" "" "" "" "" ""];
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%a %b %d}";
          tooltip = false;
        };

        battery = {
          states = {
            good = 95;
            warning = 30;
            cricital = 15;
          };

          bat = "BAT0";
          adapter = "AC";
          interval = 30;
          max-length = 20;
          format = "{icon} {capacity}%";
          format-charging = "󱐋 {capacity}%";
          format-plugged = " {capacity}%";
          format-discharging = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [" " " " " " " " " "];
        };

        network = {
          format = "{ifname}";
          format-wifi = "  {essid}";
          format-ethernet = " {ifname}";
          format-disconnected = "Disconnected ";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-wifi = "{signalStrength}%";
          max-length = 20;
        };

        "custom/media" = {
          format = "{}";
          interval = 1;
          exec = "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo ''";
        };

        "custom/keyboard" = {
          format = "  {}";
          interval = 5;
          exec = ''
            hyprctl devices -j |
            jq -r '.keyboards[] | .active_keymap' |
            tail -n2 |
            head -n1 |
            cut -c1-2 |
            tr 'a-z' 'A-Z' 2>/dev/null || echo "--"
          '';
        };

        pulseaudio = {
          format = "{icon} {volume}";
          format-bluetooth = " {volume}";
          format-muted = "  {volume}";
          format-icons = {
            headphone = "";
            phone = "";
            headset = "";
            car = "";
            default = ["" "" ""];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
        };

        "custom/quit" = {
          format = " ";
          on-click = "wlogout";
        };
      };
    };

    style = ''
      * {
        font-size: 12px;
        font-family: "Terminess Nerd Font";
        border: none;
        min-height: 0px;
        border-radius: 2px;
      }

      window#waybar {
          background: rgba(0,0,0,0);
          color: #ffffff;
      }

      #battery {
        /*background-color: #000000; */
        color: white;
      }

      #battery.charging {
        color: #ffffff;
        /* background-color: #000000; */
      }

      @keyframes blink {
        to {
          background-color: #ffffff;
          color: #000000;
        }
      }

      #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      label:focus {
        /*background-color: #000000;*/
      }

      #custom-quit {
        /*background: #000000;*/
        color: #FFFFFF;
      }

      #clock {
        color: white;
        /*background-color: #000000; */
      }

      #custom-keyboard {
        /*background-color: #000000; */
        color: #ffffff;
      }

      #custom-media {
        min-width: 100px;
        /*background-color: #66cc99;*/
        color: #2a5c45;
      }

      #pulseaudio {
        /*background: #000000; */
        color: #ffffff;
      }

      #pulseaudio.muted {
        /*background: #000000;*/
        color: #ffffff;
      }

      #network {
        /*background: #000000; */
        color: white;
      }

      #network.disconnected {
        background-color: #f53c3c;
      }

      #cpu {
       /* background-color: #000000; */
        color: #ffffff;
      }

      #memory {
        /*background-color: #000000; */
        color: #ffffff;
      }

      #workspaces button {
        box-shadow: inset 0 -3px transparent;
        color: #ffffff;
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.9);
        box-shadow: inset 0 -3px #fffff;
      }

      #workspaces button.focused {
        background-color: #64727D;
      }

      #workspaces button.urgent {
        background-color: #eb4d4b;
      }

      #mode {
        background-color: #64727D;
      }

      #tray {
        box-shadow: inset 0 -3px transparent;
        color: #ffffff;
      }
    '';
  };
}
