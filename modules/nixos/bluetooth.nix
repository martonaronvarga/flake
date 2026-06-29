{pkgs, ...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # Intel hci0 feature-read warnings are non-fatal unless pairing or audio breaks.
    package = pkgs.bluez5-experimental;
    disabledPlugins = ["sap"];
  };

  services.blueman.enable = true;
}
