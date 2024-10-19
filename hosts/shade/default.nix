{ lib, config, pkgs, inputs, ...}:


{
   imports = [
     ./system
  ];

  documentation.dev.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/var/cache"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.usu = {
      directories = [
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "Zotero"
        ".zotero"
        ".cache"
        ".local"
        ".mozilla"
        { directory = ".zsh_hist_dir"; mode = "0700"; }
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }
      ];
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "hu_HU.UTF-8/UTF-8"
    ];
  };

  time.timeZone = lib.mkDefault "Europe/Budapest";

}
