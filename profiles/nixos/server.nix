{
  lib,
  pkgs,
  ...
}: let
  observabilityTools = with pkgs; [
    btop
    iotop
    procps
    sysstat
  ];

  networkTools = with pkgs; [
    curl
    dnsutils
    iproute2
    nmap
    tcpdump
    wireguard-tools
  ];

  recoveryTools = with pkgs; [
    file
    less
    lsof
    ripgrep
    rsync
    strace
    tmux
    util-linux
  ];
in {
  services = {
    logind.settings.Login = {
      HandleLidSwitch = lib.mkDefault "ignore";
      HandleLidSwitchDocked = lib.mkDefault "ignore";
      HandleLidSwitchExternalPower = lib.mkDefault "ignore";
    };

    xserver.enable = lib.mkDefault false;

    openssh = {
      settings.PermitRootLogin = lib.mkDefault "prohibit-password";
      openFirewall = lib.mkDefault true;
    };

    fail2ban = {
      enable = lib.mkDefault true;
      maxretry = lib.mkDefault 5;
      bantime = lib.mkDefault "1h";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  system.autoUpgrade = {
    enable = lib.mkDefault false;
    allowReboot = lib.mkDefault false;
  };

  environment.systemPackages = observabilityTools ++ networkTools ++ recoveryTools;
}
