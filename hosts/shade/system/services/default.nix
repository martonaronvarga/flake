{ lib, config, pkgs, ... }: {
  imports = [ ./pipewire.nix ./power.nix ./backlight.nix ];

  services = {
    dbus.implementation = "broker";
    openssh = {
      enable = true;
      hostKeys = [
        { 
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
