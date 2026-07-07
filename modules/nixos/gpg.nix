{pkgs, ...}: {
  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  services.gnome.gnome-keyring.enable = true;
}
