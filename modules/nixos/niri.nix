{
  inputs,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  # Niri 26.04's libdisplay-info-sys requires libdisplay-info < 0.4.0.
  # The Hyprland nixpkgs input it follows has already moved to 0.4.
  niriPackage = inputs.niri.packages.${system}.niri.override {
    libdisplay-info = pkgs.libdisplay-info_0_3;
  };
in {
  programs.niri = {
    enable = true;
    package = niriPackage;
    useNautilus = false;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      prettyName = "Niri";
      comment = "Niri scrollable-tiling Wayland compositor";
      binPath = "${niriPackage}/bin/niri-session";
    };
  };

  environment.systemPackages = [pkgs.xwayland-satellite];
  environment.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";

  xdg.portal = {
    enable = true;
    config.niri = {
      default = lib.mkForce ["gnome"];
      "org.freedesktop.impl.portal.Access" = lib.mkForce "gnome";
      "org.freedesktop.impl.portal.FileChooser" = lib.mkForce "termfilechooser";
      "org.freedesktop.impl.portal.Notification" = lib.mkForce "gnome";
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
    extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
  };
}
