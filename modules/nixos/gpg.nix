{pkgs, ...}: {
  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  services.gnome.gnome-keyring.enable = true;
}
