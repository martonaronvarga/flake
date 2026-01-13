{
  pkgs,
  inputs,
  ...
}: {
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
        "org.freedesktip.portal.impl.portal.OpenURI" = ["hyprland"];
      };
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
