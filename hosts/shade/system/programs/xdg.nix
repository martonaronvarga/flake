{ pkgs, inputs, ... }: {
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.portal.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.portal.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk 
    ];
  };
}
