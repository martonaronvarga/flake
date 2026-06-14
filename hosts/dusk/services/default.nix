{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./wireguard.nix
    ./monitoring.nix
  ];

  # Network configuration
  networking = {
    nameservers = ["9.9.9.9" "1.1.1.1"];
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [51820]; # WireGuard
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    resolved = {
      enable = true;
      settings.Resolve.DNSOverTLS = "opportunistic";
    };
  };
}
