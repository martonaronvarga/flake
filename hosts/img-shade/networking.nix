{lib, ...}: {
  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = true;
  };
  networking.wireless.enable = lib.mkDefault false;
  networking.hostName = "img-shade";
}
