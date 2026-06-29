{pkgs, ...}: let
  gloamWireGuardPublicKey = "kwwH2C4zxQ+tFyATlJJ7M8YG2XEvb9gtpthocK+4CGQ=";
in {
  networking.wg-quick.interfaces.wg0 = {
    address = ["10.200.200.2/32"];
    privateKeyFile = "/persist/etc/wireguard/wg0.key";
    generatePrivateKeyFile = true;
    dns = ["1.1.1.1" "9.9.9.9"];

    peers = [
      {
        publicKey = gloamWireGuardPublicKey;
        endpoint = "129.159.11.56:51820"; # gloam
        allowedIPs = ["10.200.200.1/32"]; # do not route all trafic
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
