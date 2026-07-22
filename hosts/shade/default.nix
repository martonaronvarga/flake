{
  config,
  inventory,
  pkgs,
  ...
}: let
  inherit (inventory) network;
  gloamStateSnapshot = pkgs.writeShellApplication {
    name = "gloam-state-snapshot";
    runtimeInputs = with pkgs; [coreutils jq openssh];
    text = ''
      set -euo pipefail
      destination=/persist/state/opentofu/gloam/capacity-mirror
      install -d -m 0700 "$destination"
      staging="$(mktemp -d "$destination/.pull.XXXXXX")"
      remote=ubuntu@${network.gloam.wireguard.address}
      ssh_args=(-F /dev/null -i /persist/home/usu/.ssh/id_ed25519)
      cleanup() {
        rm -rf "$staging"
        ssh "''${ssh_args[@]}" "$remote" \
          'sudo systemctl start gloam-a1-retry.service' >/dev/null 2>&1 || true
      }
      trap cleanup EXIT
      ssh "''${ssh_args[@]}" "$remote" 'sudo systemctl stop gloam-a1-retry.service'
      ssh "''${ssh_args[@]}" "$remote" \
        'if sudo test -f /var/lib/gloam-a1-retry/terraform.tfstate; then
           sudo cat /var/lib/gloam-a1-retry/terraform.tfstate
         else
           sudo cat /opt/gloam/oci-edge/terraform.tfstate
         fi' > "$staging/terraform.tfstate"
      jq -e '.lineage and (.serial >= 0)' "$staging/terraform.tfstate" >/dev/null
      sha256sum "$staging/terraform.tfstate" > "$staging/SHA256SUMS"
      jq -r '"serial=\(.serial) lineage=\(.lineage)"' \
        "$staging/terraform.tfstate" > "$staging/metadata"
      chmod 0600 "$staging"/*
      rm -rf "$destination/current.old"
      [ ! -d "$destination/current" ] ||
        mv "$destination/current" "$destination/current.old"
      mv "$staging" "$destination/current"
      trap - EXIT
      ssh "''${ssh_args[@]}" "$remote" 'sudo systemctl start gloam-a1-retry.service'
      rm -rf "$destination/current.old"
    '';
  };
  nixBuildRemote = pkgs.writeShellApplication {
    name = "nix-build-remote";
    runtimeInputs = [pkgs.nix];
    text = ''
      set -euo pipefail
      if [ "$#" -eq 0 ]; then
        set -- .
      fi
      exec nix build --max-jobs 0 "$@"
    '';
  };
in {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./fingerprint.nix
    ./services/monitoring.nix
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
    nixPolicy = {
      trustedUsers = ["root" "usu"];
      extraSubstituters = [
        "https://numtide.cachix.org?priority=3"
        "https://nix-community.cachix.org?priority=4"
        "https://hyprland.cachix.org"
      ];
      extraTrustedPublicKeys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };

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
        shade-dusk-builder-key = {
          file = ../../secrets/shade_dusk_builder_key.age;
          owner = "root";
          mode = "0400";
          path = "/run/agenix/shade-dusk-builder-key";
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
  };

  boot.kernel.sysctl."vm.swappiness" = 10;

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = network.dusk.wireguard.address;
        protocol = "ssh-ng";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.shade-dusk-builder-key.path;
        system = "x86_64-linux";
        maxJobs = 2;
        speedFactor = 2;
        supportedFeatures = ["benchmark" "big-parallel" "kvm"];
      }
    ];
  };

  programs.ssh.knownHosts.dusk-builder = {
    hostNames = [network.dusk.wireguard.address];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrll3wZxB7KTlmTMVXRwpQUNZpjoMIWEO58nM+lwL47";
  };

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

  environment.systemPackages = [gloamStateSnapshot nixBuildRemote];

  systemd.services = {
    gloam-capacity-state-snapshot = {
      description = "Pull a consistent gloam capacity-state mirror";
      before = ["restic-backups-shade-to-dusk.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "usu";
        ExecStart = "${gloamStateSnapshot}/bin/gloam-state-snapshot";
      };
    };
    restic-backups-shade-to-dusk.wants = ["gloam-capacity-state-snapshot.service"];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8" "hu_HU.UTF-8/UTF-8"];
  };

  time.timeZone = "Europe/Budapest";

  system.stateVersion = "25.05";
}
