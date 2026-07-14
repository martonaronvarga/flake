{
  infraNetwork,
  pkgs,
  ...
}: let
  shadeSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
in {
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  networking.hostName = "gloam";
  local.flakePath = "/persist/etc/nixos";

  networking = {
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      allowedUDPPorts = [infraNetwork.gloam.wireguard.port];
      trustedInterfaces = [infraNetwork.wireguard.interface];
    };

    wg-quick.interfaces.${infraNetwork.wireguard.interface} = {
      address = [infraNetwork.gloam.wireguard.cidr];
      listenPort = infraNetwork.gloam.wireguard.port;
      privateKeyFile = "/persist/etc/wireguard/gloam.key";
      generatePrivateKeyFile = true;
      peers = [
        {
          publicKey = infraNetwork.dusk.wireguard.publicKey;
          allowedIPs = [infraNetwork.dusk.wireguard.cidr];
        }
        {
          publicKey = infraNetwork.shade.wireguard.publicKey;
          allowedIPs = [infraNetwork.shade.wireguard.cidr];
        }
      ];
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  environment.persistence."/persist".directories = [
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
        locations."/".proxyPass = "http://${infraNetwork.dusk.wireguard.address}:${toString infraNetwork.dusk.ports.website}";
      };

      "vault.${infraNetwork.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://${infraNetwork.dusk.wireguard.address}:${toString infraNetwork.dusk.ports.vaultwarden}";
        locations."/".proxyWebsockets = true;
      };

      "git.${infraNetwork.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${infraNetwork.dusk.wireguard.address}:${toString infraNetwork.dusk.ports.forgejo}";
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
      root.openssh.authorizedKeys.keys = [shadeSshKey];
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

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  time.timeZone = "Etc/UTC";

  system.stateVersion = "26.11";
}
