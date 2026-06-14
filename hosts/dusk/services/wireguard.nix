{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.wg-quick.interfaces = {
    wg0 = {
      address = ["10.200.200.2/24"];
      privateKeyFile = config.age.secrets.wg.path;

      dns = ["1.1.1.1" "9.9.9.9"];

      peers = [
        {
          # oracle
          publicKey = "k5k91pOO8k0a+O8qB1Eq0gARW3XtJ5n6V2Tzur69eUg=";

          endpoint = "141.147.15.161:51820";

          allowedIPs = ["0.0.0.0/0" "::/0"];

          persistentKeepalive = 25;
        }
      ];

      postUp = ''
        echo "wg tunnel to oracle vps is up"
      '';

      postDown = ''
        echo "wg tunnel to oracle vps is down"
      '';
    };
  };

  environment.systemPackages = with pkgs; [wireguard-tools];

  environment.persistence."/persist".directories = [
    "/secrets/wireguard"
  ];
}
