{
  inventory,
  pkgs,
  ...
}: let
  inherit (inventory) network;
  websiteAddress = network.dusk.wireguard.address;
  websitePort = network.dusk.ports.website;
in {
  # Alternative transports terminate on dusk and reach the same Bun/Astro
  # application as the public reverse proxy. Neither service needs a public
  # listener for publishing.
  services.tor = {
    enable = true;
    relay.onionServices.martonaronvarga = {
      version = 3;
      map = [
        {
          port = 80;
          target = {
            addr = websiteAddress;
            port = websitePort;
          };
        }
      ];
    };
  };

  services.i2pd = {
    enable = true;
    bandwidth = 64;
    share = 10;
    notransit = true;
    upnp.enable = false;
    proto = {
      http.enable = false;
      httpProxy.enable = false;
      socksProxy.enable = false;
      bob.enable = false;
      sam.enable = false;
      i2cp.enable = false;
      i2pControl.enable = false;
    };
    inTunnels.martonaronvarga = {
      type = "http";
      address = websiteAddress;
      port = websitePort;
      inPort = 80;
      keys = "martonaronvarga-keys.dat";
      inbound = {
        length = 3;
        quantity = 3;
      };
      outbound = {
        length = 3;
        quantity = 3;
      };
    };
  };

  systemd.services = {
    tor = {
      after = ["wg-quick-${network.wireguard.interface}.service" "martonaronvarga.service"];
      wants = ["martonaronvarga.service"];
    };
    i2pd = {
      after = ["wg-quick-${network.wireguard.interface}.service" "martonaronvarga.service"];
      wants = ["martonaronvarga.service"];
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "website-private-addresses";
      runtimeInputs = [pkgs.coreutils pkgs.i2pd-tools];
      text = ''
        onion_file=/var/lib/tor/onion/martonaronvarga/hostname
        i2p_key=/var/lib/i2pd/martonaronvarga-keys.dat

        if [ -r "$onion_file" ]; then
          printf 'ONION_ADDRESS=%s\n' "$(cat "$onion_file")"
        else
          printf 'ONION_ADDRESS=unavailable (deploy and start tor first)\n'
        fi

        if [ -r "$i2p_key" ]; then
          printf 'I2P_ADDRESS=%s\n' "$(keyinfo -b "$i2p_key" | head -n 1)"
        else
          printf 'I2P_ADDRESS=unavailable (deploy and start i2pd first)\n'
        fi
      '';
    })
  ];
}
