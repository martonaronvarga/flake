{
  inputs,
  lib,
  withSystem,
  ...
}: let
  localLib = import ../lib {
    inherit inputs lib withSystem;
  };
  inventory = import ./inventory.nix;
  capabilities = import ./capabilities.nix {
    inherit inventory lib;
  };

  profiles = {
    base = ../profiles/nixos/base.nix;
    audio = ../profiles/nixos/audio.nix;
    desktop = ../profiles/nixos/desktop.nix;
    graphical = ../profiles/nixos/graphical.nix;
    headless = ../profiles/nixos/headless.nix;
    hyprland = ../profiles/nixos/hyprland.nix;
    laptop = ../profiles/nixos/laptop.nix;
    laptop-server = ../profiles/nixos/laptop-server.nix;
    server = ../profiles/nixos/server.nix;
  };

  inherit (inventory) network;

  mkHome = {
    user,
    homeDirectory ? "/home/${user}",
    module,
  }: {config, ...}: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      overwriteBackup = true;
      extraSpecialArgs = {
        inherit inputs homeDirectory inventory;
        infraNetwork = network;
        flakePath = config.local.flakePath;
        homeUser = user;
      };
      users.${user} = module;
    };

    systemd.services."home-manager-${user}" = {
      after = ["agenix.service"];
      wants = ["agenix.service"];
    };
  };

  hosts = {
    shade = {
      system = "x86_64-linux";
      tags = ["laptop" "desktop" "personal"];
      profiles = ["base" "laptop" "graphical" "hyprland" "audio"];
      externalModules = [
        inputs.disko.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-topology.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
      ];
      modules = [
        ../hosts/shade
        ../modules/nixos/agenix.nix
        ../modules/nixos/boot-security.nix
        ../modules/nixos/host-hardening.nix
        ../modules/nixos/services/restic-sftp.nix
        ../modules/nixos/services/wireguard-client.nix
        (capabilities.mkWireGuardClient {
          hostName = "shade";
          privateKeyFile = "/run/agenix/shade-wg-private-key";
          routeGuardTargets = [
            network.dusk.wireguard.address
          ];
        })
        (capabilities.mkResticSftpJob {
          name = "shade-to-dusk";
          user = "usu";
          identityFile = "/persist/home/usu/.ssh/id_ed25519";
          passwordFile = "/run/agenix/restic-shade-password";
          paths = [
            "/persist/home/usu"
          ];
          exclude = [
            "/persist/home/usu/.cache"
            "/persist/home/usu/.local/share/Trash"
            "/persist/home/usu/.mozilla/firefox/*/cache2"
            "/persist/home/usu/flake/result"
            "/persist/home/usu/flake/result-*"
            "**/.direnv"
            "**/node_modules"
            "**/target"
          ];
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 6"
          ];
          timerConfig = {
            OnCalendar = "03:30";
            RandomizedDelaySec = "45m";
            Persistent = true;
          };
          target = {
            user = "usu";
            host = network.dusk.wireguard.address;
            repositoryPath = "/persist/backups/restic/shade";
            hostKey = "${network.dusk.wireguard.address} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrll3wZxB7KTlmTMVXRwpQUNZpjoMIWEO58nM+lwL47";
            knownHostsName = "dusk-restic";
          };
        })
        (capabilities.mkResticSftpJob {
          name = "shade-to-offsite";
          enable = false;
        })
        (mkHome {
          user = "usu";
          homeDirectory = "/home/usu";
          module = import ../modules/home;
        })
      ];
    };

    dusk = {
      system = "x86_64-linux";
      tags = ["laptop-server" "server" "edge"];
      profiles = ["base" "laptop-server"];
      externalModules = [
        inputs.disko.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-topology.nixosModules.default
      ];
      modules = [
        ../hosts/dusk
        ../modules/nixos/agenix.nix
        ../modules/nixos/boot-security.nix
        ../modules/nixos/host-hardening.nix
        ../modules/nixos/services/restic-sftp.nix
        ../modules/nixos/services/wireguard-client.nix
        (capabilities.mkWireGuardClient {
          hostName = "dusk";
          privateKeyFile = "/run/agenix/dusk-wg-private-key";
          dns = ["1.1.1.1" "9.9.9.9"];
        })
        (capabilities.mkResticSftpJob {
          name = "dusk-to-offsite";
          enable = false;
        })
      ];
      deployment = {
        targetHost = network.dusk.wireguard.address;
        targetPort = 22;
        targetUser = "usu";
        privilegeEscalationCommand = ["sudo" "-H" "--"];
        sshOptions = ["-F" "/dev/null" "-J" "${network.gloam.sshUser}@${network.gloam.publicIp}"];
        buildOnTarget = false;
        allowLocalDeployment = true;
      };
    };

    gloam = {
      system = "aarch64-linux";
      tags = ["oracle" "server" "edge"];
      profiles = ["base" "headless" "server"];
      externalModules = [
        inputs.disko.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
        inputs.agenix.nixosModules.default
        inputs.nix-topology.nixosModules.default
      ];
      modules = [
        ../hosts/gloam
      ];
      deployment = {
        targetHost = "gloam";
        targetPort = 22;
        targetUser = network.gloam.sshUser;
        privilegeEscalationCommand = ["sudo" "-H" "--"];
        buildOnTarget = true;
      };
    };
  };

  mkModules = host:
    host.externalModules
    ++ map (profile: profiles.${profile}) host.profiles
    ++ host.modules;

  resolvedHosts = lib.mapAttrs (_: host: host // {resolvedModules = mkModules host;}) hosts;

  mkConfiguration = name: host:
    localLib.mkHost {
      inherit name;
      inherit (host) system;
      modules = host.resolvedModules;
      specialArgs = {
        infraInventory = inventory;
        inherit inventory;
        infraNetwork = network;
      };
    };
in {
  _module.args = {
    infraHosts = resolvedHosts;
    infraInventory = inventory;
    infraNetwork = network;
  };

  flake = {
    nixosConfigurations = lib.mapAttrs mkConfiguration resolvedHosts;
  };

  perSystem = {system, ...}: {
    packages = lib.mapAttrs' (
      name: _host:
        lib.nameValuePair name
        inputs.self.nixosConfigurations.${name}.config.system.build.toplevel
    ) (lib.filterAttrs (_: host: host.system == system) resolvedHosts);
  };
}
