{
  lib,
  pkgs,
  inputs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      binPath = lib.mkDefault "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/start-hyprland";
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      common."org.freedesktop.portal.OpenURI" = ["hyprland"];
      hyprland = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.portal.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.portal.impl.portal.ScreenCast" = ["hyprland"];
      };
    };
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.pathsToLink = ["/share/icons"];
}
