{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./services/backups.nix
    ./services
    ./services/vaultwarden.nix
    ./services/forgejo.nix
    ./services/forgejo-runner.nix
    ./services/matrix.nix
    ./services/matrix-lab.nix
    ./services/rfcs.nix
    ./services/website.nix
    ./services/private-web.nix
    ./services/radicle.nix
  ];

  networking.hostName = "dusk";

  local = {
    bootSecurity = {
      enableSecureBoot = true;
      enableTpmUnlock = true;
      luksDeviceNames = ["cryptroot"];
    };

    agenix = {
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
        dusk-wg-private-key = {
          file = ../../secrets/dusk_wg_private_key.age;
          owner = "root";
          mode = "0400";
          path = "/run/agenix/dusk-wg-private-key";
        };
        forgejo-mailer-password = {
          file = ../../secrets/forgejo_mailer_password.age;
          owner = "forgejo";
          mode = "0400";
          path = "/run/agenix/forgejo-mailer-password";
        };
        forgejo-runner-token = {
          file = ../../secrets/forgejo_runner_token.age;
          owner = "root";
          group = "forgejo-runner-secret";
          mode = "0440";
          path = "/run/agenix/forgejo-runner-token";
        };
        radicle-seed-key = {
          file = ../../secrets/radicle_seed_key.age;
          owner = "radicle";
          mode = "0400";
          path = "/run/agenix/radicle-seed-key";
        };
        restic-external-password = {
          file = ../../secrets/restic_external_password.age;
          owner = "root";
          mode = "0400";
          path = "/run/agenix/restic-external-password";
        };
        restic-shade-password = {
          file = ../../secrets/restic_shade_password.age;
          owner = "root";
          mode = "0400";
          path = "/run/agenix/restic-shade-password";
        };
        vaultwarden-env = {
          file = ../../secrets/vaultwarden_env.age;
          owner = "vaultwarden";
          mode = "0400";
          path = "/run/agenix/vaultwarden-env";
        };
        website-env = {
          file = ../../secrets/website_env.age;
          owner = "martonaronvarga";
          mode = "0400";
          path = "/run/agenix/website-env";
        };
      };
    };
  };

  # Persistence for server
  environment.persistence."/persist" = {
    directories =
      [
        "/etc/agenix"
        "/var/lib/grafana"
        "/var/lib/vaultwarden"
        "/var/lib/forgejo"
        "/var/lib/gitea-runner"
        "/var/lib/containers"
        {
          directory = "/var/lib/radicle";
          user = "radicle";
          group = "radicle";
          mode = "0750";
        }
        {
          directory = "/var/lib/continuwuity";
          user = "continuwuity";
          group = "continuwuity";
          mode = "0700";
        }
        "/var/lib/postgresql"
        {
          directory = "/var/lib/martonaronvarga";
          user = "martonaronvarga";
          group = "martonaronvarga";
          mode = "0750";
        }
        "/var/lib/tor"
        {
          directory = "/var/lib/i2pd";
          user = "i2pd";
          group = "i2pd";
          mode = "0700";
        }
      ]
      ++ lib.optionals inventory.matrixLab.enable [
        "/var/lib/matrix-synapse"
        "/var/lib/mautrix-slack"
        "/var/lib/draupnir"
      ];
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "dusk-enroll-tpm-unlock";
      text = ''
        set -euo pipefail
        exec /run/current-system/sw/bin/secureboot-enroll-tpm-unlock "$@"
      '';
    })
  ];

  fileSystems."/var".neededForBoot = true;

  # Server user
  users = {
    mutableUsers = false;
    users = {
      usu = {
        isNormalUser = true;
        shell = pkgs.zsh;
        hashedPasswordFile = config.age.secrets.usu-password-hash.path;
        extraGroups = ["wheel" "networkmanager"];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade"
        ];
      };
      nix-builder = {
        isSystemUser = true;
        group = "nix-builder";
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = [
          "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6It5C9Uef0VCYGXMfNWmhh2UN4WmorGWIYGO8tKjdv shade-to-dusk-nix-builder"
        ];
      };
    };
    groups.nix-builder = {};
  };

  local.nixPolicy.trustedUsers = ["root" "nix-builder" "usu"];

  # The ThinkPad's TPM times out on systemd 261's optional login NvPCR
  # extension and remains unusable until a cold boot. LUKS unlock uses PCR 7
  # in the initrd and does not depend on this login audit measurement.
  systemd.suppressedSystemUnits = ["systemd-pcrlogin@.service"];

  services.openssh.settings.AllowUsers = lib.mkForce ["usu" "nix-builder"];

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
