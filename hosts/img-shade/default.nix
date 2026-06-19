{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./networking.nix
  ];

  config = {
    system.stateVersion = "26.05";
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      supportedFilesystems = lib.mkForce ["btrfs" "vfat" "reiserfs" "f2fs" "xfs" "ntfs" "cifs"];
      kernelParams = ["nomodeset" "intel_pstate=disable" "acpi_osi=Linux" "pci=noaer"];
    };

    console = {
      font = "Lat2-Terminus16";
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      inputMethod = {
        enable = true;
        type = "ibus";
        ibus.engines = with pkgs.ibus-engines; [libpinyin typing-booster];
      };
    };

    services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    environment.systemPackages = with pkgs; [
      coreutils-full
      git
      wget
      curl
      vim
    ];

    users.users.nixos.shell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
