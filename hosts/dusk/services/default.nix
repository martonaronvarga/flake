{lib, ...}: {
  imports = [
    ./monitoring.nix
  ];

  # Network configuration
  networking = {
    networkmanager = {
      enable = true;
      ensureProfiles.profiles.dusk-ethernet = {
        connection = {
          id = "Wired connection 1";
          uuid = "4a8b76ed-d21f-3e8a-8c55-7e5eaeb79783";
          type = "ethernet";
          interface-name = "enp0s31f6";
        };
        ipv4 = {
          method = "auto";
          ignore-auto-dns = true;
        };
        ipv6 = {
          method = "auto";
          addr-gen-mode = "stable-privacy";
          ignore-auto-dns = true;
        };
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = []; # do not expose
      trustedInterfaces = ["wg0"];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };

    resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
          "2620:fe::fe#dns.quad9.net"
          "2606:4700:4700::1111#cloudflare-dns.com"
        ];
        Domains = ["~."];
        DNSOverTLS = lib.mkForce "yes";
      };
    };
  };
}
