{ lib, config, pkgs, inputs, ... }:

{
  imports = [
    ./system
  ];

  documentation.dev.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib"
      "/var/cache"
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager/"
    ];
    files = [ 
      "/etc/machine-id" 
    ];
    users.usu = {
      directories = [
        "documents"
        "downloads"
        "music"
        "pictures"
        "videos"
        "zotero"
        ".zotero"
        ".cache"
        ".local"
        ".mozilla"
        ".config/zsh/.zsh_history"
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
      ];
    };
  };
  
  fileSystems."/persist".neededForBoot = true;

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
  

  services.btrbk.instances.snapshot = {
    # snapshot on the start and the middle of every hour.
    onCalendar = "*:00,30";
    settings = {
      timestamp_format = "long-iso";
      preserve_day_of_week = "monday";
      preserve_hour_of_day = "23";
      # All snapshots are retained for at least 6 hours regardless of other policies.
      snapshot_preserve_min = "6h";
      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume."persist".snapshot_preserve = "48h 7d";
        subvolume."persist/home".snapshot_preserve = "48h 7d 4w";
      };
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "hu_HU.UTF-8/UTF-8" ];
  };

  time.timeZone = lib.mkDefault "Europe/Budapest";

  system.stateVersion = "23.11";
}
