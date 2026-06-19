{pkgs, ...}: let
  gloamWireGuardPublicKey = "k5k91pOO8k0a+O8qB1Eq0gARW3XtJ5n6V2Tzur69eUg=";
in {
  networking.wg-quick.interfaces.wg0 = {
    address = ["10.200.200.2/24"];
    privateKeyFile = "/persist/etc/wireguard/wg0.key";
    generatePrivateKeyFile = true;
    dns = ["1.1.1.1" "9.9.9.9"];

    peers = [
      {
        publicKey = gloamWireGuardPublicKey;
        endpoint = "141.147.15.161:51820";
        allowedIPs = ["0.0.0.0/0" "::/0"];
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
