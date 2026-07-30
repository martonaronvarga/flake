{
  config,
  lib,
  pkgs,
  ...
}: let
  json = pkgs.formats.json {};

  waybarVpn = pkgs.writeShellApplication {
    name = "waybar-vpn";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
      pkgs.kitty
      pkgs.networkmanager
    ];
    text = ''
      active_vpns() {
        nmcli --terse --fields NAME,TYPE connection show --active |
          sed -n '/:\(vpn\|wireguard\)$/s/:.*//p'
      }

      case "''${1:-status}" in
        status)
          active="$(active_vpns | paste -sd, -)"
          if [[ -n "$active" ]]; then
            jq -cn --arg text "$active" '{text: $text, class: "connected", tooltip: ("Active VPN: " + $text)}'
          else
            jq -cn '{text: "OFF", class: "disconnected", tooltip: "No active VPN"}'
          fi
          ;;
        select)
          if [[ "''${2:-}" != "--menu" ]]; then
            exec kitty --class waybar-vpn --title "Select VPN" "$0" select --menu
          fi
          connection="$(nmcli --terse --fields NAME,TYPE connection show |
            sed -n '/:\(vpn\|wireguard\)$/s/:.*//p' |
            sort -u |
            ${lib.getExe config.programs.fzf.package} --header='enter: connect  esc: cancel')" || exit 0
          [[ -n "$connection" ]] && nmcli connection up id "$connection"
          ;;
        disconnect)
          while IFS= read -r connection; do
            [[ -n "$connection" ]] && nmcli connection down id "$connection"
          done < <(active_vpns)
          ;;
        *)
          echo "usage: waybar-vpn {status|select|disconnect}" >&2
          exit 2
          ;;
      esac
    '';
  };

  waybarTemperatures = pkgs.writeShellApplication {
    name = "waybar-temperatures";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      read_sensor() {
        local wanted="$1" input="$2" directory name
        for directory in /sys/class/hwmon/hwmon*; do
          [[ -r "$directory/name" ]] || continue
          name="$(<"$directory/name")"
          if [[ "$name" == "$wanted" && -r "$directory/$input" ]]; then
            awk '{ printf "%.0f", $1 / 1000 }' "$directory/$input"
            return 0
          fi
        done
        return 1
      }

      cpu="$(read_sensor coretemp temp1_input || true)"
      nvme="$(read_sensor nvme temp1_input || true)"
      wifi="$(read_sensor iwlwifi_1 temp1_input || read_sensor iwlwifi temp1_input || true)"
      output=""
      [[ -n "$cpu" ]] && output="CPU <span color='#849696'>''${cpu}°C</span>"
      [[ -n "$nvme" ]] && output="''${output:+$output · }NVMe <span color='#849696'>''${nvme}°C</span>"
      [[ -n "$wifi" ]] && output="''${output:+$output · }WiFi <span color='#849696'>''${wifi}°C</span>"
      printf '%s\n' "''${output:-temperature unavailable}"
    '';
  };

  mkMutedConfig = compositor: let
    isNiri = compositor == "niri";
    workspaces =
      if isNiri
      then "niri/workspaces"
      else "hyprland/workspaces";
    language =
      if isNiri
      then "niri/language"
      else "hyprland/language";
  in
    json.generate "waybar-${compositor}-muted.json" {
      layer = "top";
      position = "top";
      height = 26;
      spacing = 8;
      modules-left = ["privacy" "group/network" "group/hardware" "group/resources"];
      modules-center = [];
      modules-right = ["backlight" "group/audio" "battery" "group/clock"];

      "group/network" = {
        orientation = "horizontal";
        modules = ["network#stats" "network#connection" "custom/vpn"];
        drawer = {
          transition-left-to-right = true;
          transition-duration = 500;
        };
      };
      "group/hardware" = {
        orientation = "horizontal";
        modules = ["cpu" "custom/temperatures"];
        drawer = {
          transition-left-to-right = true;
          transition-duration = 500;
        };
      };
      "group/resources" = {
        orientation = "horizontal";
        modules = ["memory" "disk#root"];
        drawer = {
          transition-left-to-right = true;
          transition-duration = 500;
        };
      };
      "group/taskbar" = {
        orientation = "horizontal";
        modules = [workspaces language "tray"];
        drawer = {
          transition-left-to-right = true;
          transition-duration = 500;
        };
      };
      "group/audio" = {
        orientation = "horizontal";
        modules = ["wireplumber" "bluetooth"];
        drawer = {
          transition-left-to-right = false;
          transition-duration = 500;
        };
      };
      "group/clock" = {
        orientation = "horizontal";
        modules = ["clock#time" "clock#date"];
        drawer = {
          transition-left-to-right = false;
          transition-duration = 500;
        };
      };

      privacy = {
        icon-size = 18;
        icon-spacing = 4;
      };
      network = {
        interval = 2;
        format-wifi = "  {essid}  ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
        format-ethernet = "󰈀  {ifname}  ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
        format-disconnected = "󰖪  offline";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}\nGateway: {gwaddr}";
      };
      "network#stats" = {
        family = "ipv4";
        interval = 2;
        format = "BWD {bandwidthDownBytes} <span color='#849696'>{bandwidthUpBytes}</span>";
        tooltip-format = "{ifname}";
      };
      "network#connection" = {
        family = "ipv4";
        format = "{ifname}";
        format-wifi = "WiFi {essid} <span color='#849696'>{signalStrength}%</span>";
        format-ethernet = "ETH {ipaddr}/<span color='#849696'>{cidr}</span>";
        format-disconnected = "OFF";
        tooltip-format = "{ifname} via {gwaddr}";
      };
      "custom/vpn" = {
        format = "VPN <span color='#849696'>{}</span>";
        return-type = "json";
        exec = "${lib.getExe waybarVpn} status";
        on-click = "${lib.getExe waybarVpn} select";
        on-click-middle = "${lib.getExe waybarVpn} disconnect";
        interval = 30;
      };
      cpu = {
        interval = 10;
        format = "FRQ {avg_frequency:3.2f}GHz <span color='#849696'>{usage}%</span>";
        states = {
          warning = 70;
          critical = 90;
        };
      };
      "custom/temperatures" = {
        exec = lib.getExe waybarTemperatures;
        interval = 10;
        format = "{}";
      };
      memory = {
        interval = 60;
        format = "MEM {used:3.1f}GiB/<span color='#849696'>{total:3.1f}GiB</span>";
        tooltip-format = "{used:0.1f} GiB / {total:0.1f} GiB";
      };
      disk = {
        interval = 30;
        path = "/";
        format = "󰋊  {percentage_used}%";
        tooltip-format = "{used} / {total}";
      };
      "disk#root" = {
        interval = 360;
        path = "/";
        format = "SSD {used}/<span color='#849696'>{total}</span>";
      };
      tray = {
        spacing = 0;
        icon-size = 12;
      };
      backlight = {
        device = "intel_backlight";
        format = "BRT {percent}%";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-bluetooth = " {volume}%";
        format-muted = "  muted";
        format-icons.default = ["" "" ""];
        scroll-step = 1;
        on-click = "pavucontrol";
      };
      wireplumber = {
        format = "{icon} {node_name}/<span color='#849696'>{volume}</span>";
        format-muted = " X ";
        format-icons = ["+--" "++-" "+++"];
        on-click = "pavucontrol";
      };
      bluetooth = {
        format = "<span color='#849696'>BT</span>";
        format-connected = "BT";
        format-disabled = "<span color='#333333'>BT</span>";
        on-click = "blueman-manager";
      };
      battery = {
        bat = "BAT0";
        adapter = "AC";
        interval = 30;
        states = {
          good = 95;
          warning = 10;
          critical = 5;
        };
        format-time = "{H}:{m}";
        format = "{icon} {time} <span color='#849696'>{capacity}%</span>";
        format-discharging = "{icon} <span color='#E4D00A'>{capacity}%</span>";
        format-discharging-warning = "{icon} <span color='#FF5F1F'>{capacity}%</span>";
        format-discharging-critical = "{icon} <span color='#FF3131'>{capacity}%</span>";
        format-charging = "CHG <span color='#DAF7A6'>{capacity}%</span><span color='#849696'> @ {power:2.0f}W</span>";
        format-full = "{icon} <span color='#849696'>{capacity}%</span>";
        format-not-charging = "NOP <span color='#849696'>{capacity}%</span>";
        format-icons = ["---" "#--" "##-" "###" "PWR"];
      };
      clock = {
        interval = 1;
        format = "{:%H:%M}";
        format-alt = "{:%a %Y-%m-%d}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
      "clock#time" = {
        interval = 60;
        format = "{0:%H:%M} <span color='#849696'>{0:%Z}</span>";
        tooltip = false;
      };
      "clock#date" = {
        interval = 60;
        format = "<span color='#849696'>{:%a %e %b %Y}</span>";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>";
        calendar = {
          mode = "year";
          mode-mon-col = 2;
          weeks-pos = "right";
          on-scroll = 1;
        };
        actions = {
          on-click-right = "mode";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };
      "custom/quit" = {
        format = "";
        on-click = "wlogout";
        tooltip = false;
      };
      ${workspaces} = {
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          active = "";
          focused = "";
          urgent = "";
          default = "";
        };
      };
      ${language} = {
        format = "  {}";
        format-en = "EN";
        format-hu = "HU";
      };
    };

  mkMinimalConfig = compositor: let
    isNiri = compositor == "niri";
    workspaces =
      if isNiri
      then "niri/workspaces"
      else "hyprland/workspaces";
    keyboardCommand =
      if isNiri
      then ''niri msg keyboard-layouts | sed -n 's/^ *\* //p' | cut -c1-2 | tr 'a-z' 'A-Z' 2>/dev/null || echo "--"''
      else ''hyprctl devices -j | jq -r '.keyboards[] | .active_keymap' | tail -n2 | head -n1 | cut -c1-2 | tr 'a-z' 'A-Z' 2>/dev/null || echo "--"'';
  in
    json.generate "waybar-${compositor}-minimal.json" {
      layer = "top";
      position = "top";
      height = 26;
      margin-left = 0;
      margin-right = 0;
      margin-top = 0;
      margin-bottom = 0;
      spacing = 12;
      modules-left = ["cpu" "memory" workspaces];
      modules-center = ["custom/media"];
      modules-right = ["tray" "custom/keyboard" "network" "backlight" "battery" "pulseaudio" "clock" "custom/quit"];

      ${workspaces} = {
        format = "{icon}";
        all-outputs = true;
        on-click = "activate";
        format-icons =
          {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            urgent = " ";
            focused = " ";
            default = " ";
          }
          // lib.optionalAttrs isNiri {active = " ";};
      };
      tray = {
        spacing = 6;
        icon-size = 13;
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
          critical = 15;
        };
        bat = "BAT0";
        adapter = "AC";
        interval = 30;
        max-length = 20;
        format = "{icon} {capacity}%";
        format-charging = "󱐋 {capacity}%";
        format-plugged = " {capacity}%";
        format-discharging = "  {capacity}%";
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
        max-length = 25;
      };
      "custom/media" = {
        format = "{}";
        interval = 1;
        exec = "playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo ''";
      };
      "custom/keyboard" = {
        format = "  {}";
        interval = 5;
        exec = keyboardCommand;
      };
      pulseaudio = {
        format = "{icon} {volume}";
        format-bluetooth = " {volume}";
        format-muted = "  {volume}";
        format-icons = {
          headphone = " ";
          phone = " ";
          headset = "";
          car = " ";
          default = ["" " " " "];
        };
        scroll-step = 1;
        on-click = "pavucontrol";
      };
      "custom/quit" = {
        format = " ";
        on-click = "wlogout";
      };
    };

  hyprlandMinimalConfig = mkMinimalConfig "hyprland";
  hyprlandMutedConfig = mkMutedConfig "hyprland";
  niriMinimalConfig = mkMinimalConfig "niri";
  niriMutedConfig = mkMutedConfig "niri";

  minimalStyle = pkgs.writeText "waybar-minimal.css" ''
    * {
      font-size: 13px;
      font-family: "Terminess Nerd Font";
      border: none;
      min-height: 0;
      border-radius: 2px;
    }

    window#waybar {
      background: #000000;
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
        color: #ffffff;
        color: #000000;
      }
    }

    #battery.critical:not(.charging) {
      color: #f53c3c;
      animation-name: blink;
      animation-duration: 3s;
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
      box-shadow: inset 0 -3px #ffffff;
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

  mutedStyle = pkgs.writeText "waybar-muted.css" ''
    * {
      border: none;
      border-radius: 0;
      min-height: 26px;
      font-family: "TX-02", "Symbols Nerd Font Mono";
      font-size: 11px;
      font-weight: 400;
    }
    window#waybar {
      background-color: #000000;
      border-bottom: none;
      color: #536161;
    }
    tooltip {
      background: #000000;
      color: #849696;
      border: 1px solid #536161;
    }
    .module {
      margin: 0 10px;
      padding: 0;
      color: #536161;
    }
    #clock, #workspaces button.active, #workspaces button.focused { color: #849696; }
    #workspaces { margin-left: 20px; }
    #workspaces button {
      min-width: 32px;
      padding: 4px 6px;
      color: #536161;
      background: transparent;
      box-shadow: none;
    }
    #workspaces button:hover {
      color: #ffffff;
      background: transparent;
      box-shadow: none;
      text-shadow: inherit;
    }
    #workspaces button.active, #workspaces button.focused {
      background: transparent;
      box-shadow: none;
    }
    #workspaces button.urgent { color: #ffffff; background: #e27878; }
    #bluetooth { min-width: 32px; }
    #language { color: #cccccc; }
    #clock { margin-right: 4px; }
    #cpu.warning { color: #e5c890; }
    #cpu.critical { color: #e78284; }
    #privacy-item.screenshare, #privacy-item.audio-in { color: #ffffff; }
    #battery.warning { color: #849696; }
    #battery.critical:not(.charging), #network.disconnected { color: #ffffff; }
  '';

  waybarLauncher = pkgs.writeShellApplication {
    name = "start-waybar";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      state_file="''${XDG_STATE_HOME:-$HOME/.local/state}/wayland-appearance/waybar"
      profile="minimal"
      if [[ -r "$state_file" ]]; then
        profile="$(<"$state_file")"
      fi
      if [[ "$profile" == transparent ]]; then
        profile="minimal"
        install -d -m 0700 "$(dirname "$state_file")"
        printf '%s\n' "$profile" >"$state_file"
      fi
      case "$profile" in
        minimal) style=${lib.escapeShellArg (toString minimalStyle)} ;;
        muted) style=${lib.escapeShellArg (toString mutedStyle)} ;;
        *) style=${lib.escapeShellArg (toString minimalStyle)} ;;
      esac
      if [[ -n "''${NIRI_SOCKET:-}" ]]; then
        case "$profile" in
          muted) config=${lib.escapeShellArg (toString niriMutedConfig)} ;;
          *) config=${lib.escapeShellArg (toString niriMinimalConfig)} ;;
        esac
      else
        case "$profile" in
          muted) config=${lib.escapeShellArg (toString hyprlandMutedConfig)} ;;
          *) config=${lib.escapeShellArg (toString hyprlandMinimalConfig)} ;;
        esac
      fi
      exec ${lib.getExe pkgs.waybar} --config "$config" --style "$style"
    '';
  };

  selectWaybar = pkgs.writeShellApplication {
    name = "select-waybar";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kitty
      pkgs.systemd
    ];
    text = ''
      if [[ "''${1:-}" != "--menu" ]]; then
        exec kitty --class waybar-selector --title "Select Waybar" "$0" --menu
      fi
      choice="$(printf 'Minimal\tminimal\nMuted TX-02\tmuted\n' | \
        env -u FZF_DEFAULT_OPTS_FILE FZF_DEFAULT_OPTS= \
          ${lib.getExe config.programs.fzf.package} \
          --height=100% \
          --layout=reverse \
          --cycle \
          --border \
          --info=inline \
          --prompt='>' \
          --scrollbar='|' \
          --separator='-' \
          --no-bold \
          --pointer='>' \
          --marker='*' \
          --color='bg:#000000,bg+:#1a1a1a,fg:#d0d0d0,fg+:#ffffff,hl:#ffffff,hl+:#ffffff,border:#333333,label:#aaaaaa,info:#aaaaaa,header:#aaaaaa,prompt:#d0d0d0,pointer:#ffffff,marker:#ffffff,spinner:#aaaaaa,query:#ffffff,gutter:#000000' \
          --delimiter=$'\t' --with-nth=1 --header='enter: apply  esc: cancel')" || exit 0
      profile="$(cut -f2 <<<"$choice")"
      case "$profile" in
        minimal|muted) ;;
        *) exit 1 ;;
      esac
      state_directory="''${XDG_STATE_HOME:-$HOME/.local/state}/wayland-appearance"
      install -d -m 0700 "$state_directory"
      printf '%s\n' "$profile" >"$state_directory/waybar"
      systemctl --user restart waybar.service
    '';
  };
in {
  home.packages = [
    pkgs.waybar
    selectWaybar
  ];

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      Documentation = "man:waybar(5)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = lib.getExe waybarLauncher;
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
