{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$MdAORfTDZl7kOH5hldBAU.$W8czUSqOHSCSlfEGuSTXzt.aKyQX5iQdfudxxuL6hk7";
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "tty" "docker"];
  };

  services.getty.autologinUser = "usu";

  local.networking.privacyDns = {
    enable = true;
    exactSsids = ["Buba"];
    ssidPrefixes = ["Telekom"];
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/colord"
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
    ];
  };

  fileSystems."/home".neededForBoot = true;

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
        subvolume."home".snapshot_preserve = "48h 7d 4w";
      };
    };
  };

  documentation.dev.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "hu_HU.UTF-8/UTF-8"];
  };

  time.timeZone = "Europe/Budapest";

  system.stateVersion = "25.05";
}
