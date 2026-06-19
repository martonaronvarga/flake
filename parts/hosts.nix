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

  mkHome = {
    user,
    homeDirectory ? "/home/${user}",
    module,
  }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs homeDirectory;
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
        inputs.nvf.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-topology.nixosModules.default
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
      ];
      modules = [
        ../hosts/shade
        ../modules/nixos/agenix.nix
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
        inputs.nix-topology.nixosModules.default
      ];
      modules = [
        ../hosts/dusk
      ];
      deployment = {
        targetHost = "dusk.local";
        targetPort = 22;
        targetUser = "root";
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
    };
in {
  _module.args.infraHosts = resolvedHosts;

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
