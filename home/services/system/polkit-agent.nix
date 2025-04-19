{pkgs, ...}: {
  systemd.user.services.hyprpolkitagent = {
    Unit.Description = "Hyprland Polkit Agent";
    Unit.After = ["graphical-session.target"];
    Unit.Wants = ["graphical-session.target"];

    Install = {
      WantedBy = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent}";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
