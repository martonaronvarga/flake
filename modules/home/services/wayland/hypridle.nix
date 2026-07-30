{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  niriPackage = inputs.niri.packages.${system}.niri;

  suspendScript = pkgs.writeShellScript "suspend-script" ''
    # check if any player has status "Playing"
    ${lib.getExe pkgs.playerctl} -a status | ${lib.getExe pkgs.ripgrep} Playing -q
    # only suspend if nothing is playing
    if [ $? == 1 ]; then
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';

  lockScript = pkgs.writeShellScript "lock-screen" ''
    if ! ${pkgs.procps}/bin/pidof hyprlock >/dev/null; then
      exec ${lib.getExe config.programs.hyprlock.package}
    fi
  '';

  brillo = lib.getExe pkgs.brillo;

  dpmsScript = pkgs.writeShellScript "wayland-dpms" ''
    case "''${1:-}" in
      off)
        if [ -n "''${NIRI_SOCKET:-}" ]; then
          exec ${niriPackage}/bin/niri msg action power-off-monitors
        fi
        exec ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
        ;;
      on)
        if [ -n "''${NIRI_SOCKET:-}" ]; then
          exec ${niriPackage}/bin/niri msg action power-on-monitors
        fi
        exec ${pkgs.hyprland}/bin/hyprctl dispatch dpms on
        ;;
      *)
        echo "usage: wayland-dpms {on|off}" >&2
        exit 2
        ;;
    esac
  '';

  # timeout after which DPMS kicks in
  timeout = 600;
in {
  # screen idle
  services.hypridle = {
    enable = true;

    package = inputs.hypridle.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;

    settings = {
      general = {
        # login1 can emit another lock event while Hyprlock already owns the
        # session during suspend. A second instance would contend for the
        # single fprintd device and can leave an unreleasable stale claim.
        lock_cmd = lockScript.outPath;
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
      };

      listener = [
        {
          timeout = timeout - 10;
          # save the current brightness and dim the screen over a period of
          # 1 second
          on-timeout = "${brillo} -O; ${brillo} -u 1000000 -S 10";
          # brighten the screen over a period of 500ms to the saved value
          on-resume = "${brillo} -I -u 500000";
        }
        {
          inherit timeout;
          on-timeout = "${dpmsScript} off";
          on-resume = "${dpmsScript} on";
        }
        {
          timeout = timeout + 10;
          on-timeout = suspendScript.outPath;
        }
      ];
    };
  };
}
