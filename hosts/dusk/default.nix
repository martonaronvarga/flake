{
  config,
  lib,
  pkgs,
  ...
}: let
  tpmUnlockDevice = "/dev/disk/by-partlabel/root";
  tpmUnlockPcrs = config.local.bootSecurity.tpmPcrs;
in {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./services/backups.nix
    ./services/wireguard.nix
    ./services/monitoring.nix
    ./services/vaultwarden.nix
    ./services/website.nix
  ];

  networking.hostName = "dusk";

  local.bootSecurity = {
    enableSecureBoot = false;
    enableTpmUnlock = true;
    luksDeviceNames = ["cryptroot"];
  };

  local.agenix = {
    identityPaths = ["/persist/etc/agenix/dusk-age-key.txt"];
    secrets = {
      grafana-admin-password = {
        file = ../../secrets/grafana_admin_password.age;
        owner = "grafana";
        mode = "0400";
        path = "/run/agenix/grafana-admin-password";
      };
      grafana-secret-key = {
        file = ../../secrets/grafana_secret_key.age;
        owner = "grafana";
        mode = "0400";
        path = "/run/agenix/grafana-secret-key";
      };
      usu-password-hash = {
        file = ../../secrets/usu_password_hash.age;
        owner = "root";
        mode = "0400";
        path = "/run/agenix/usu-password-hash";
      };
      vaultwarden-env = {
        file = ../../secrets/vaultwarden_env.age;
        owner = "vaultwarden";
        mode = "0400";
        path = "/run/agenix/vaultwarden-env";
      };
    };
  };

  # Persistence for server
  environment.persistence."/persist" = {
    directories = [
      "/etc/agenix"
      "/var/lib/grafana"
      "/var/lib/vaultwarden"
      "/var/lib/wireguard"
    ];
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "dusk-enroll-tpm-unlock";
      runtimeInputs = with pkgs; [cryptsetup sudo systemd];
      text = ''
        set -euo pipefail

        if [ "$(id -u)" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        if [ ! -e /dev/tpmrm0 ] && [ ! -e /dev/tpm0 ]; then
          echo "No TPM device found at /dev/tpmrm0 or /dev/tpm0." >&2
          exit 1
        fi

        if [ ! -b ${lib.escapeShellArg tpmUnlockDevice} ]; then
          echo "LUKS device is not available: ${tpmUnlockDevice}" >&2
          exit 1
        fi

        echo "Enrolling TPM2 unlock for ${tpmUnlockDevice} using PCR policy ${tpmUnlockPcrs}."
        echo "You will be asked for the existing LUKS passphrase."
        systemd-cryptenroll ${lib.escapeShellArg tpmUnlockDevice} \
          --wipe-slot=tpm2 \
          --tpm2-device=auto \
          --tpm2-pcrs=${lib.escapeShellArg tpmUnlockPcrs}

        echo
        echo "Current LUKS enrollments:"
        systemd-cryptenroll ${lib.escapeShellArg tpmUnlockDevice}
      '';
    })
  ];

  fileSystems."/var".neededForBoot = true;

  # Server user
  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets.usu-password-hash.path;
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade"
    ];
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 80;
      scan_timeout = 20;
      username = {
        format = "[$username]($style)";
        show_always = true;
        style_root = "bright-red bold";
        style_user = "bright-white bold";
      };
      hostname = {
        format = "[$ssh_symbol$hostname]($style) ";
        ssh_only = false;
        ssh_symbol = "ssh ";
      };
      character = {
        error_symbol = "[>](bold red)";
        success_symbol = "[>](bold white)";
      };
      nix_shell = {
        format = "[$symbol$name]($style)";
        heuristic = false;
        symbol = "nix ";
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
    allowedUDPPorts = [5353];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  time.timeZone = "Europe/Budapest";

  system.stateVersion = "26.11";
}
