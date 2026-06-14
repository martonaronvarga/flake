_: {
  services.resolved = {
    enable = true;
    settings.Resolve.DNSOverTLS = "opportunistic";
    settings.Resolve.DNSSEC = "false";
    settings.Resolve.FallbackDNS = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
      "1.1.1.1#cloudflare-dns.com"
    ];
  };
}
