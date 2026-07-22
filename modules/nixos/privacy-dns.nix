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
  disabledConnectionFile = "/run/privacy-dns-disabled-connection";
  dispatcher = pkgs.writeShellScript "privacy-dns-dispatcher" ''
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
    connection_uuid="$(${pkgs.networkmanager}/bin/nmcli -t -g GENERAL.CON-UUID device show "$iface" 2>/dev/null || true)"
    if [ -z "$ssid" ] || [ "$ssid" = "--" ]; then
      exit 0
    fi

    apply_network_dns() {
      mapfile -t network_dns < <(
        ${pkgs.networkmanager}/bin/nmcli -t -f DHCP4.OPTION,DHCP6.OPTION device show "$iface" |
          ${pkgs.gnused}/bin/sed -n -E \
            's/^DHCP[46]\.OPTION\[[0-9]+\]:(domain_name_servers|dhcp6_name_servers) = / /p' |
          ${pkgs.coreutils}/bin/tr ' ' '\n' |
          ${pkgs.gnugrep}/bin/grep -v '^$'
      )

      ${pkgs.systemd}/bin/resolvectl revert "$iface"
      if [ "''${#network_dns[@]}" -gt 0 ]; then
        ${pkgs.systemd}/bin/resolvectl dns "$iface" "''${network_dns[@]}"
        ${pkgs.systemd}/bin/resolvectl domain "$iface" '~.'
        ${pkgs.systemd}/bin/resolvectl default-route "$iface" yes
        ${pkgs.systemd}/bin/resolvectl dnsovertls "$iface" no
      fi
    }

    if [ -r ${disabledConnectionFile} ] && [ "$(cat ${disabledConnectionFile})" = "$connection_uuid" ]; then
      apply_network_dns
      ${pkgs.util-linux}/bin/logger -t privacy-dns "using network-provided DNS on $ssid by temporary override"
      exit 0
    fi

    matched=${
      if cfg.allWifi
      then "1"
      else "0"
    }
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
      apply_network_dns
      ${pkgs.util-linux}/bin/logger -t privacy-dns "using network-provided DNS on $ssid"
      exit 0
    fi

    ${pkgs.systemd}/bin/resolvectl dns "$iface" ${dnsServers}
    ${pkgs.systemd}/bin/resolvectl domain "$iface" ${searchDomains}
    ${pkgs.systemd}/bin/resolvectl dnsovertls "$iface" yes
    ${pkgs.util-linux}/bin/logger -t privacy-dns "enabled encrypted DNS on $ssid"
  '';
  privacyDns = pkgs.writeShellApplication {
    name = "privacy-dns";
    runtimeInputs = [pkgs.coreutils pkgs.networkmanager pkgs.systemd];
    text = ''
      if [ "$EUID" -ne 0 ]; then
        exec /run/wrappers/bin/sudo "$0" "$@"
      fi

      active_wifi() {
        nmcli -t -f DEVICE,TYPE,STATE device status |
          while IFS=: read -r iface type state; do
            if [ "$type" = wifi ] && [ "$state" = connected ]; then
              printf '%s\n' "$iface"
            fi
          done
      }

      case "''${1:-status}" in
        off)
          iface="$(active_wifi | head -n1)"
          if [ -z "$iface" ]; then
            echo "No connected Wi-Fi interface." >&2
            exit 1
          fi
          uuid="$(nmcli -t -g GENERAL.CON-UUID device show "$iface")"
          ssid="$(nmcli -t -g GENERAL.CONNECTION device show "$iface")"
          printf '%s\n' "$uuid" > ${disabledConnectionFile}
          ${dispatcher} "$iface" up
          resolvectl flush-caches
          echo "Encrypted DNS disabled for $ssid until disconnect, reboot, or 'privacy-dns on'."
          ;;
        on)
          rm -f ${disabledConnectionFile}
          while IFS= read -r iface; do
            ${dispatcher} "$iface" up
          done < <(active_wifi)
          resolvectl flush-caches
          echo "Encrypted DNS enabled."
          ;;
        status)
          if [ -r ${disabledConnectionFile} ]; then
            echo "Encrypted DNS is temporarily disabled for one saved Wi-Fi connection."
          else
            echo "Encrypted DNS is enabled by policy."
          fi
          resolvectl status
          ;;
        *)
          echo "Usage: privacy-dns {on|off|status}" >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  options.local.networking.privacyDns = {
    enable = lib.mkEnableOption "SSID-scoped privacy DNS for trusted Wi-Fi networks";

    allWifi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use privacy DNS on every Wi-Fi connection unless temporarily disabled.";
    };

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
    environment = {
      etc."NetworkManager/dispatcher.d/60-privacy-dns".source = dispatcher;
      systemPackages = [privacyDns];
    };
  };
}
