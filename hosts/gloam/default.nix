{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) domain matrixLab network radicle rfcs;
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
      allowedTCPPorts = [80 443 network.dusk.ports.radicleNode];
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

    virtualHosts =
      {
        "martonaronvarga.dev" = {
          enableACME = true;
          forceSSL = true;
          serverAliases = ["www.martonaronvarga.dev"];
          locations = {
            "/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.website}";
            "/.well-known/matrix/" = {
              proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.matrix}";
              extraConfig = ''
                access_log off;
              '';
            };
          };
        };

        "matrix.${domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.matrix}";
            extraConfig = ''
              access_log off;
              client_max_body_size 50M;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
            '';
          };
        };
      }
      // lib.optionalAttrs matrixLab.enable {
        ${matrixLab.serverName} = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "=/.well-known/matrix/server".extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin * always;
              return 200 '{"m.server":"${matrixLab.publicHost}:443"}';
            '';
            "=/.well-known/matrix/client".extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin * always;
              return 200 '{"m.homeserver":{"base_url":"https://${matrixLab.publicHost}"}}';
            '';
            "=/.well-known/matrix/support".extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin * always;
              return 200 '{"contacts":[{"matrix_id":"${matrixLab.adminMxid}","role":"m.role.admin"}]}';
            '';
          };
        };

        ${matrixLab.publicHost} = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.matrixLab}";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 50M;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
            '';
          };
        };
      }
      // {
        ${radicle.seedDomain} = lib.mkIf radicle.enable {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.radicleHttpd}";
        };

        ${radicle.webDomain} = lib.mkIf radicle.enable {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/api/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.radicleHttpd}";
            "/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.radicleExplorer}";
          };
        };

        ${rfcs.domain} = lib.mkIf rfcs.enable {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://${network.dusk.wireguard.address}:${toString network.dusk.ports.rfcs}";
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

  systemd = {
    sockets.radicle-proxy = lib.mkIf radicle.enable {
      description = "Public Radicle seed socket";
      wantedBy = ["sockets.target"];
      listenStreams = ["0.0.0.0:${toString network.dusk.ports.radicleNode}"];
      socketConfig.NoDelay = true;
    };

    services.radicle-proxy = lib.mkIf radicle.enable {
      description = "Proxy Radicle traffic to dusk over WireGuard";
      after = ["wg-quick-${network.wireguard.interface}.service"];
      wants = ["wg-quick-${network.wireguard.interface}.service"];
      serviceConfig = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${network.dusk.wireguard.address}:${toString network.dusk.ports.radicleNode}";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      };
    };

    tmpfiles.rules = [
      "d /persist/etc/wireguard 0700 root root -"
    ];
  };

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
