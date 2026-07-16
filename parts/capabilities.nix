{
  inventory,
  lib,
}: let
  inherit (inventory) network;
in {
  mkWireGuardClient = {
    hostName,
    privateKeyFile,
    peerName ? "gloam",
    dns ? [],
    routeGuardTargets ? [],
  }: let
    host = network.${hostName};
    peer = network.${peerName};
  in {
    local.networking.wireguardClient = {
      enable = true;
      interface = network.wireguard.interface;
      addresses = [host.wireguard.cidr];
      inherit privateKeyFile dns;
      peers = [
        {
          publicKey = peer.wireguard.publicKey;
          endpoint = "${peer.publicIp}:${toString peer.wireguard.port}";
          allowedIPs = [network.wireguard.subnet];
          persistentKeepalive = 25;
        }
      ];
      routeGuard.targets = routeGuardTargets;
    };
  };

  mkResticSftpJob = {
    name,
    enable ? true,
    user ? "root",
    paths ? [],
    exclude ? [],
    pruneOpts ? [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ],
    checkOpts ? ["--read-data-subset=1G"],
    timerConfig ? {
      OnCalendar = "05:30";
      RandomizedDelaySec = "1h";
      Persistent = true;
    },
    identityFile ? null,
    passwordFile ? null,
    target ? null,
  }: {
    local.backups.resticSftp.jobs.${name} =
      {
        inherit enable;
      }
      // lib.optionalAttrs enable {
        inherit user paths exclude pruneOpts checkOpts timerConfig identityFile passwordFile target;
      };
  };
}
