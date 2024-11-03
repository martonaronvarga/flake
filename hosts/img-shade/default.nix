{ config, lib, pkgs, ... }: {

  imports = [
    ./networking.nix
  ];


  config = {
    system.stateVersion = "23.11";
    boot.kernelPackages = pkgs.linuxPackages_latest;

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


   disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              label = "esp";
              start = "0";
              end = "4G";
              # EFI Filesystem
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              label = "swap";
              start = "4G";
              end = "24G";
              content = {
                type = "luks";
                name = "cryptswap";
                content = { type = "swap"; };
              };
            };
            root = {
              label = "root";
              start = "24G";
              end = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist/home" = {
                      mountpoint = "/persist/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/.snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

   services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

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
