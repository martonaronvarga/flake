{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) domain network;
  vaultwardenDomain = "vault.${domain}";
  vaultwardenEnvGuard = pkgs.writeShellScript "vaultwarden-env-guard" ''
    set -eu

    env_file=${config.age.secrets.vaultwarden-env.path}

    if ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*SIGNUPS_ALLOWED[[:space:]]*=[[:space:]]*true[[:space:]]*$' "$env_file"; then
      echo "vaultwarden-env must not override SIGNUPS_ALLOWED=true" >&2
      exit 1
    fi

    if ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*ADMIN_TOKEN[[:space:]]*=' "$env_file"; then
      echo "vaultwarden-env must not expose the public admin panel with ADMIN_TOKEN" >&2
      exit 1
    fi
  '';
in {
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    environmentFile = config.age.secrets.vaultwarden-env.path;
    backupDir = "/persist/backups/vaultwarden";
    config = {
      DOMAIN = "https://${vaultwardenDomain}";
      ENABLE_WEBSOCKET = true;
      INVITATIONS_ALLOWED = false;
      ROCKET_ADDRESS = network.dusk.wireguard.address;
      ROCKET_PORT = network.dusk.ports.vaultwarden;
      SIGNUPS_ALLOWED = false;
    };
  };

  systemd.services.vaultwarden = {
    after = ["wg-quick-${network.wireguard.interface}.service"];
    requires = ["wg-quick-${network.wireguard.interface}.service"];
    serviceConfig.ExecStartPre = lib.mkBefore [
      "${vaultwardenEnvGuard}"
    ];
  };

  networking.firewall.interfaces.${network.wireguard.interface}.allowedTCPPorts = [
    network.dusk.ports.vaultwarden
  ];
}
