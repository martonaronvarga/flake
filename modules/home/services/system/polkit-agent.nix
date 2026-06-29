{pkgs, ...}: {
  home.packages = [
    pkgs.hyprpolkitagent
  ];

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland polkit authentication agent";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
