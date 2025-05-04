{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./system
  ];

  documentation.dev.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/colord"
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager/"
      "/var/lib/systemd/coredump"
      "/secrets"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
    ];
    users.usu = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "Zotero"
        ".zotero"
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
        ".local/share/direnv"
      ];
    };
  };

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/boot".neededForBoot = true;

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
        subvolume."home".snapshot_preserve = "48h 7d 4w";
      };
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "hu_HU.UTF-8/UTF-8"];
  };

  time.timeZone = lib.mkDefault "Europe/Budapest";

  system.stateVersion = "25.05";
}
