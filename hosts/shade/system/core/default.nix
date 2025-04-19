{ lib, config, pkgs, ... }:

{
  imports = [ ./boot.nix ./security.nix ./users.nix ];

  services.getty.autologinUser = "usu";

  systemd.user.services.uwsm = {
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${config.programs.uwsm.package}/bin/uwsm start hyprland";
      Restart = "on-failure";
    };
  };
}
