{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./services/wireguard.nix
    ./services/monitoring.nix
    ./services/restic.nix
  ];

  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.usu-password-hash.path;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "tty"];
  };

  local = {
    flakePath = "/persist/home/usu/flake";

    agenix = {
      identityPaths = ["/persist/home/usu/.ssh/id_ed25519"];
      secrets = {
        usu = {
          file = ../../secrets/usu.age;
          owner = "usu";
          mode = "600";
        };
        usu-password-hash.file = ../../secrets/usu_password_hash.age;
        aerc-client-id = {
          file = ../../secrets/aerc_client_id.age;
          owner = "usu";
          path = "/run/agenix/aerc-client-id";
        };
        aerc-client-secret = {
          file = ../../secrets/aerc_client_secret.age;
          owner = "usu";
          path = "/run/agenix/aerc-client-secret";
        };
        oci-config = {
          file = ../../secrets/oci_config.age;
          owner = "usu";
          mode = "0400";
          path = "/run/agenix/oci-config";
        };
        oci-private-key = {
          file = ../../secrets/oci_private_key.age;
          owner = "usu";
          mode = "0400";
          path = "/run/agenix/oci-private-key";
        };
        restic-shade-password = {
          file = ../../secrets/restic_shade_password.age;
          owner = "usu";
          mode = "0400";
          path = "/run/agenix/restic-shade-password";
        };
        shade-wg-private-key = {
          file = ../../secrets/shade_wg_private_key.age;
          owner = "root";
          mode = "0400";
          path = "/run/agenix/shade-wg-private-key";
        };
      };
    };

    networking.privacyDns = {
      enable = true;
      exactSsids = ["Buba"];
      ssidPrefixes = ["Telekom"];
    };

    bootSecurity = {
      enableSecureBoot = true;
      enableTpmUnlock = true;
      luksDeviceNames = ["cryptroot" "cryptswap"];
    };

    backups.offsiteRestic = {
      enable = false;
      name = "shade-to-offsite";
      user = "usu";
      paths = [
        "/persist/home/usu"
      ];
      exclude = [
        "/persist/home/usu/.cache"
        "/persist/home/usu/.local/share/Trash"
        "/persist/home/usu/.mozilla/firefox/*/cache2"
        "/persist/home/usu/flake/result"
        "/persist/home/usu/flake/result-*"
        "**/.direnv"
        "**/node_modules"
        "**/target"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };

  boot.kernel.sysctl."vm.swappiness" = 10;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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
