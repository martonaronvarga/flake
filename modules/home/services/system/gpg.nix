{
  pkgs,
  lib,
  ...
}: {
  services.gpg-agent = {
    enable = true;

    enableExtraSocket = true;
    enableSshSupport = false;

    # terminal-only pinentry
    pinentry.package = pkgs.pinentry-tty;
    pinentry.program = "pinentry-tty";

    # avoid desktop keyring/passphrase-cache interaction
    noAllowExternalCache = true;

    # reasonable cache
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;

    enableZshIntegration = true;
  };

  programs.zsh.initContent = lib.mkAfter ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
  '';
}
