{ lib, pkgs, inputs, ... }: {
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = lib.mkForce false; # default is off to use flake
  };

  environment.variables.NIXOS_OZONE_WL = "1";
}
