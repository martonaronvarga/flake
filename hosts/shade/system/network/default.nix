{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./spotify.nix];

  networking = {
    # use quad9 with DNS over TLS
    nameservers = ["9.9.9.9" "1.1.1.1"];
    hostName = "shade";

    networkmanager = {
      enable = lib.mkDefault true;
      dns = "systemd-resolved";
      wifi.powersave = true;
      insertNameservers = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings.UseDns = true;
    };

    # DNS resolver
    resolved = {
      enable = true;
      domains = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
      dnsovertls = "opportunistic";
      dnssec = "allow-downgrade";
    };
  };
}
