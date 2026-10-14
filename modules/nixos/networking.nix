{lib, ...}: {
  networking.networkmanager = {
    enable = lib.mkDefault true;
    dns = lib.mkDefault "systemd-resolved";
    wifi.powersave = lib.mkDefault true;
    settings = {
      main.systemd-resolved = true;
      connection."connection.mdns" = 2;
    };
  };
}
