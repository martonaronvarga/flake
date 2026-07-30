{
  lib,
  pkgs,
  inputs,
  ...
}: {
  # xdg-document-portal needs the privileged fusermount3 wrapper when
  # exporting its document store for terminal file choosers.
  programs = {
    fuse.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    uwsm = {
      enable = true;
      waylandCompositors.hyprland = {
        prettyName = "Hyprland";
        binPath = lib.mkDefault "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/start-hyprland";
      };
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common = {
        default = ["gnome"];
        "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        "org.freedesktop.portal.OpenURI" = ["hyprland"];
      };
      hyprland = {
        default = ["hyprland" "gnome"];
        "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        "org.freedesktop.portal.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.portal.impl.portal.ScreenCast" = ["hyprland"];
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-termfilechooser
    ];
  };

  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    pathsToLink = ["/share/icons"];
  };
}
