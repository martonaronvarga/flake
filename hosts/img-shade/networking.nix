{lib, ...}: {
  networking = {
    hostName = "img-shade";
    networkmanager = {
      enable = true;
      wifi.scanRandMacAddress = true;
    };
    wireless.enable = lib.mkDefault false;
  };
}
