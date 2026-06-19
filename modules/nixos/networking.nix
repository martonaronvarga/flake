{
  lib,
  pkgs,
  ...
}: {
  networking.networkmanager = {
    enable = lib.mkDefault true;
    dns = lib.mkDefault "systemd-resolved";
    plugins = lib.mkDefault [pkgs.networkmanager-fortisslvpn];
    wifi.powersave = lib.mkDefault true;
    settings = {
      main.systemd-resolved = true;
      connection."connection.mdns" = 2;
    };
  };
}
