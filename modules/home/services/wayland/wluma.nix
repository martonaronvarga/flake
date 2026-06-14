{
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.wluma = {
    Unit = {
      Description = "Automatic backlight control";
      After = ["graphical-session.target"];
      Requires = ["graphical-session.target"];
    };
    Service = {
      ExecStart = lib.getExe pkgs.wluma;
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  xdg.configFile."wluma/config.toml".source = (pkgs.formats.toml {}).generate "wluma-config" {
    als.time = {
      thresholds = {
        "0" = "night";
        "7" = "dark";
        "9" = "dim";
        "11" = "normal";
        "13" = "bright";
        "16" = "normal";
        "18" = "dark";
        "20" = "night";
      };
    };

    output.backlight = [
      {
        capturer = "wayland";
        name = "eDP-1";
        path = "/sys/class/backlight/intel_backlight";
      }
    ];

    # need to fix ddcutil first
    # output.ddcutil = [
    #   {
    #     capturer = "none";
    #     name = "BenQ BL2283";
    #   }
    # ];
  };
}
