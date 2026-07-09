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
    ./services/website.nix
  ];

  networking.hostName = "dusk";

  local.agenix = {
    identityPaths = ["/persist/etc/agenix/dusk-age-key.txt"];
    secrets.usu-password-hash = {
      file = ../../secrets/usu_password_hash.age;
      owner = "root";
      mode = "0400";
      path = "/run/agenix/usu-password-hash";
    };
  };

  # Persistence for server
  environment.persistence."/persist" = {
    directories = [
      "/etc/agenix"
      "/var/lib/wireguard"
    ];
  };

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
