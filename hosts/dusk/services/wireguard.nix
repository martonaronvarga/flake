{
  infraNetwork,
  pkgs,
  ...
}: {
  networking.wg-quick.interfaces.wg0 = {
    address = [infraNetwork.dusk.wireguard.cidr];
    privateKeyFile = "/persist/etc/wireguard/wg0.key";
    generatePrivateKeyFile = true;
    dns = ["1.1.1.1" "9.9.9.9"];

    peers = [
      {
        publicKey = infraNetwork.gloam.wireguard.publicKey;
        endpoint = "${infraNetwork.gloam.publicIp}:${toString infraNetwork.gloam.wireguard.port}";
        allowedIPs = [infraNetwork.wireguard.subnet];
        persistentKeepalive = 25;
      }
    ];
  };

  environment.systemPackages = with pkgs; [wireguard-tools];

  environment.persistence."/persist".directories = [
    "/etc/wireguard"
  ];

  systemd.tmpfiles.rules = [
    "d /persist/etc/wireguard 0700 root root -"
  ];
}
