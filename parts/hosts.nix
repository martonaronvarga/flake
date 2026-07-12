{
  inputs,
  lib,
  withSystem,
  ...
}: let
  localLib = import ../lib {
    inherit inputs lib withSystem;
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

  network = {
    domain = "martonaronvarga.dev";
    wireguard = {
      subnet = "10.200.200.0/24";
      interface = "wg0";
    };
    gloam = {
      publicIp = "129.159.11.56";
      sshUser = "ubuntu";
      wireguard = {
        address = "10.200.200.1";
        cidr = "10.200.200.1/24";
        port = 51820;
        publicKey = "kwwH2C4zxQ+tFyATlJJ7M8YG2XEvb9gtpthocK+4CGQ=";
      };
    };
    dusk = {
      wireguard = {
        address = "10.200.200.2";
        cidr = "10.200.200.2/32";
        publicKey = "5jfqQTM6Ms/JrcQLKOBFKT+LDWxlXv+NMj8fPG76iTI=";
      };
      ports = {
        website = 8080;
        vaultwarden = 8222;
        grafana = 3000;
        prometheus = 9090;
        nodeExporter = 9100;
      };
    };
    shade = {
      wireguard = {
        address = "10.200.200.3";
        cidr = "10.200.200.3/32";
        publicKey = "/IvwqxIkfzB3DxDqeKzH2Wf5S5anky4Gdor6jvq4MA8=";
      };
      ports.nodeExporter = 9100;
    };
  };

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
        inherit inputs homeDirectory;
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
        inputs.nvf.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-topology.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
      ];
      modules = [
        ../hosts/shade
        ../modules/nixos/agenix.nix
        ../modules/nixos/boot-security.nix
        ../modules/nixos/host-hardening.nix
        ../modules/nixos/neovim.nix
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
        targetUser = "root";
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
      specialArgs.infraNetwork = network;
    };
in {
  _module.args = {
    infraHosts = resolvedHosts;
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
