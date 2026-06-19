{pkgs, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./services/wireguard.nix
  ];

  # Persistence for server
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/wireguard"
    ];
  };

  fileSystems."/var".neededForBoot = true;

  # Server user
  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade"
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
    allowedUDPPorts = [51820]; # WireGuard
  };

  security.sudo.wheelNeedsPassword = false;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  time.timeZone = "Europe/Budapest";

  system.stateVersion = "26.05";
}
