{ pkgs, ... }: {

  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = true;
  };
  networking.wireless.enable = false;
  networking.hostName = "img-shade";
}
