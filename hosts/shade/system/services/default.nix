{ lib, config, pkgs, ... }: {
  imports = [ ./pipewire.nix ./power.nix ./backlight.nix ];

  services = { dbus.implementation = "broker"; };
}
