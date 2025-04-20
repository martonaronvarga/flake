{pkgs, ...}: {
  home.packages = [
    pkgs.hyprpolkitagent
  ];

  programs.uwsm.extraSessionCommands = ''
    systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    systemctl --user enable --now hyprpolkitagent.service
    systemctl --user start hypridle.service
  '';
}
