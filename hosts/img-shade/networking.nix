{ pkgs, ... }: {
  networking.resolvconf.useLocalResolver = true;

  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = true;
  };
}
