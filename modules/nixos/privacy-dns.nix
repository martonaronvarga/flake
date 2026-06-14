{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.networking.privacyDns;
  exactSsids = lib.escapeShellArgs cfg.exactSsids;
  ssidPrefixes = lib.escapeShellArgs cfg.ssidPrefixes;
  dnsServers = lib.escapeShellArgs cfg.servers;
  searchDomains = lib.escapeShellArgs cfg.domains;
in {
  options.local.networking.privacyDns = {
    enable = lib.mkEnableOption "SSID-scoped privacy DNS for trusted Wi-Fi networks";

    exactSsids = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Wi-Fi SSIDs that should use privacy DNS exactly.";
    };

    ssidPrefixes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Wi-Fi SSID prefixes that should use privacy DNS.";
    };

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net"];
      description = "DNS-over-TLS capable servers passed to systemd-resolved.";
    };

    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["~."];
      description = "Resolved routing domains for privacy DNS.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."NetworkManager/dispatcher.d/60-privacy-dns".source = pkgs.writeShellScript "60-privacy-dns" ''
      set -euo pipefail

      iface="$1"
      state="$2"

      case "$state" in
        up|dhcp4-change|dhcp6-change) ;;
        *) exit 0 ;;
      esac

      device_type="$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null || true)"
      if [ "$device_type" != "wifi" ]; then
        exit 0
      fi

      ssid="$(${pkgs.networkmanager}/bin/nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null || true)"
      if [ -z "$ssid" ] || [ "$ssid" = "--" ]; then
        exit 0
      fi

      matched=0
      for candidate in ${exactSsids}; do
        if [ "$ssid" = "$candidate" ]; then
          matched=1
        fi
      done

      for prefix in ${ssidPrefixes}; do
        case "$ssid" in
          "$prefix"*) matched=1 ;;
        esac
      done

      if [ "$matched" != 1 ]; then
        ${pkgs.util-linux}/bin/logger -t privacy-dns "leaving DHCP DNS on $ssid"
        exit 0
      fi

      ${pkgs.systemd}/bin/resolvectl dns "$iface" ${dnsServers}
      ${pkgs.systemd}/bin/resolvectl domain "$iface" ${searchDomains}
      ${pkgs.systemd}/bin/resolvectl dnsovertls "$iface" yes
      ${pkgs.util-linux}/bin/logger -t privacy-dns "enabled privacy DNS on $ssid"
    '';
  };
}
