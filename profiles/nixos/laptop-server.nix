{lib, ...}: {
  imports = [
    ./laptop.nix
    ./server.nix
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "ignore";
    HandleLidSwitchExternalPower = lib.mkForce "ignore";
    HandlePowerKey = lib.mkDefault "suspend";
  };
}
