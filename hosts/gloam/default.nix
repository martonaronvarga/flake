{pkgs, ...}: let
  shadeSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
  # Bootstrap value; replace with dusk's generated public key after first activation.
  duskWireGuardPublicKey = "IujkG119YPr2cVQzJkSLYCdjpHIDjvr/qH1w1tdKswY=";
in {
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  local.flakePath = "/persist/etc/nixos";

  networking = {
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [51820];
      trustedInterfaces = ["wg0"];
    };

    wg-quick.interfaces.wg0 = {
      address = ["10.200.200.1/24"];
      listenPort = 51820;
      privateKeyFile = "/persist/etc/wireguard/wg0.key";
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
  ];

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

  system.stateVersion = "26.05";
}
