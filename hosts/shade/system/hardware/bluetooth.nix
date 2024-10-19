{pkgs, ...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs.bluez5-experimental;
    disabledPlugins = [ "sap" ];
  };

  services.blueman.enable = true;
}
