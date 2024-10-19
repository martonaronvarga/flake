{ inputs, config, lib, pkgs, ... }: with lib;
{
  imports = [
    ./networking.nix
  ];


  environment.systemPackages = [ (pkgs.callPackage "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"}/pkgs/agenix.nix" {}) ];
  config = {
    system.stateVersion = "23.11";
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # This is a dummy key in ISO image, we shall not worry about its security.
    # Agenix breaks in LiveCD due to https://github.com/ryantm/agenix/issues/165.
    age.identityPaths = [ (pkgs.writeText "img_key_ed25519" (builtins.readFile ../../secrets/img_key_ed25519)) ];

    programs.gnupg.agent.enable = true;

    boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

    # Set internationalisation properties.
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
    i18n = {
      defaultLocale = "en_US.UTF-8";
      inputMethod = {
        enable = true;
        type = "ibus";
        ibus.engines = with pkgs.ibus-engines; [ libpinyin typing-booster ];
      };
    };

    # Whitelist wheel users to do anything
    # This is useful for things like pkexec
    #
    # WARNING: this is dangerous for systems
    # outside the installation-cd and shouldn't
    # be used anywhere else.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';


   services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    disko.devices = (import ./../shade/system/disko/default.nix { });
    # This is a LiveCD, please don't enable disk config in NixOS.
    disko.enableConfig = false;

    environment.systemPackages = with pkgs; let
      create-disko-pkg = name: path: (runCommandLocal "disko-${name}" { } ''
        mkdir -p $out/bin
        install ${path} $out/bin/disko-${name}
      '');
    in
    [
      (writeShellScriptBin "install-script"
        (builtins.readFile ./install.sh))

      (create-disko-pkg "main" config.system.build.diskoScript)
      (create-disko-pkg "format" config.system.build.formatScript)
      (create-disko-pkg "mount" config.system.build.mountScript)
      coreutils-full
      git
      wget
      vim
    ];

    users.users.nixos.shell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
