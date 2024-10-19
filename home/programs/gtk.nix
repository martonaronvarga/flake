{
  lib,
  pkgs,
  config,
  ...
}: {
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors;
    name = "Catppuccin Mocha Dark";
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    font = {
      name = "Terminus (TTF) Bold";
      package = pkgs.terminus_font_ttf;
      size = 9;
    };

    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    iconTheme = {
      name = "Dracula";
      package = pkgs.dracula-icon-theme;
    };

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
  };

  xdg.configFile."gtk-4.0/gtk.css".enable = lib.mkForce false;
}
