{
  inventory,
  lib,
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
    settings = {
      bandwidth = 64;
      share = 10;
      notransit = true;
      upnp.enabled = false;
      http.enabled = false;
      httpproxy.enabled = false;
      socksproxy.enabled = false;
      bob.enabled = false;
      sam.enabled = false;
      i2cp.enabled = false;
      i2pcontrol.enabled = false;
    };
    serverTunnels.martonaronvarga = {
      host = websiteAddress;
      port = websitePort;
      inport = 80;
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

  # Keep the persistent bind mount and its existing identity. DynamicUser
  # would try to move this mount into /var/lib/private during activation.
  users = {
    users.i2pd = {
      isSystemUser = true;
      uid = 150;
      group = "i2pd";
    };
    groups.i2pd.gid = 150;
  };

  systemd.services = {
    tor = {
      after = ["wg-quick-${network.wireguard.interface}.service" "martonaronvarga.service"];
      wants = ["martonaronvarga.service"];
    };
    i2pd = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        StateDirectoryMode = "0700";
      };
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
