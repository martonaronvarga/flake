{lib, ...}: {
  imports = [
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/low-memory.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/privacy-dns.nix
  ];

  services = {
    power-profiles-daemon.enable = lib.mkDefault true;
    upower.enable = lib.mkDefault true;
    dbus.implementation = lib.mkDefault "broker";

    # Suspend on lid close unless a more specific profile overrides it.
    logind.settings.Login = {
      HandlePowerKey = lib.mkDefault "suspend";
      HandleLidSwitch = lib.mkDefault "suspend";
      HandleLidSwitchExternalPower = lib.mkDefault "lock";
    };
  };

  # Battery optimizations
  powerManagement.enable = lib.mkDefault true;

  # Backlight control
  hardware.brillo.enable = lib.mkDefault true;

  security.sudo.extraConfig = lib.mkDefault "Defaults lecture = never";
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
