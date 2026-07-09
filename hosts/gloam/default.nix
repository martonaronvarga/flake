{pkgs, ...}: let
  shadeSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
  duskWireGuardPublicKey = "5jfqQTM6Ms/JrcQLKOBFKT+LDWxlXv+NMj8fPG76iTI=";
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
      allowedUDPPorts = [51820];
      trustedInterfaces = ["wg0"];
    };

    wg-quick.interfaces.wg0 = {
      address = ["10.200.200.1/24"];
      listenPort = 51820;
      privateKeyFile = "/persist/etc/wireguard/gloam.key";
      generatePrivateKeyFile = true;
      peers = [
        {
          publicKey = duskWireGuardPublicKey;
          allowedIPs = ["10.200.200.2/32"];
        }
      ];
    };
  };

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

    virtualHosts."martonaronvarga.dev" = {
      serverAliases = ["www.martonaronvarga.dev"];
      locations."/".proxyPass = "http://10.200.200.2:8080";
    };
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

  security.sudo.wheelNeedsPassword = false;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  time.timeZone = "Etc/UTC";

  system.stateVersion = "26.11";
}
