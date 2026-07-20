{
  config,
  inventory,
  pkgs,
  ...
}: let
  inherit (inventory) domain network;
  shadeSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
in {
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  networking.hostName = "gloam";
  local.flakePath = "/persist/etc/nixos";
  local.agenix = {
    identityPaths = ["/persist/etc/agenix/gloam-age-key.txt"];
    secrets.gloam-wg-private-key = {
      file = ../../secrets/gloam_wg_private_key.age;
      owner = "root";
      mode = "0400";
      path = "/run/agenix/gloam-wg-private-key";
    };
  };

  networking = {
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [network.gloam.wireguard.port];
      interfaces.${network.wireguard.interface}.allowedTCPPorts = [22];
    };

    wg-quick.interfaces.${network.wireguard.interface} = {
      address = [network.gloam.wireguard.cidr];
      listenPort = network.gloam.wireguard.port;
      privateKeyFile = config.age.secrets.gloam-wg-private-key.path;
      peers = [
        {
          publicKey = network.dusk.wireguard.publicKey;
          allowedIPs = [network.dusk.wireguard.cidr];
        }
        {
          publicKey = network.shade.wireguard.publicKey;
          allowedIPs = [network.shade.wireguard.cidr];
        }
      ];
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  environment.persistence."/persist".directories = [
    "/etc/agenix"
    "/etc/wireguard"
    "/var/lib/acme"
    "/var/lib/nginx"
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "martonaronvarga.dev" = {
        enableACME = true;
        forceSSL = true;
        serverAliases = ["www.martonaronvarga.dev"];
        locations."/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.website}";
      };

      "vault.${domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.vaultwarden}";
        locations."/".proxyWebsockets = true;
      };

      "git.${domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.forgejo}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 512M;
          '';
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "martonaronvarga@gmail.com";
  };

  systemd.tmpfiles.rules = [
    "d /persist/etc/wireguard 0700 root root -"
  ];

  fileSystems."/var".neededForBoot = true;

  users = {
    mutableUsers = false;
    users = {
      usu = {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = [shadeSshKey];
      };
    };
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

  security.sudo.wheelNeedsPassword = false;

  services.openssh.settings = {
    AllowUsers = ["usu"];
    PermitRootLogin = "no";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  time.timeZone = "Etc/UTC";

  system.stateVersion = "26.11";
}
