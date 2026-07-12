{
  config,
  infraNetwork,
  ...
}: {
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    environmentFile = config.age.secrets.vaultwarden-env.path;
    backupDir = "/persist/backups/vaultwarden";
    config = {
      DOMAIN = "https://vault.${infraNetwork.domain}";
      ENABLE_WEBSOCKET = true;
      INVITATIONS_ALLOWED = true;
      ROCKET_ADDRESS = infraNetwork.dusk.wireguard.address;
      ROCKET_PORT = infraNetwork.dusk.ports.vaultwarden;
      SIGNUPS_ALLOWED = false;
    };
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.vaultwarden
  ];
}
