{ pkgs, inputs, ... }: {
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = true;
  };

  environment.variables.NIXOS_OZONE_WL = "1";
}
