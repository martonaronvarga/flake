{
  description = "Marton A. Varga's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    utils.url = "github:zimbatm/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland?submodules=1";

    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    utils,
    disko,
    lanzaboote,
    impermanence,
    home-manager,
    agenix,
    alejandra,
    hyprland,
    hypridle,
    hyprland-plugins,
    hyprland-contrib,
    hyprlock,
    hyprpaper,
    hyprcursor,
    nvf,
    ...
  }: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      #nix build .#nixosConfigurations.img-shade.config.system.build.isoImage
      img-shade = lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs self lib;};
        modules = [
          agenix.nixosModules.default
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/img-shade
          {
            environment.systemPackages = [agenix.packages.x86_64-linux.default];
          }
        ];
      };

      shade = lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs self lib;};
        modules = [
          disko.nixosModules.default
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          agenix.nixosModules.default
          nvf.nixosModules.default

          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen

          ./hosts/shade
          ./modules

          {
            home-manager.extraSpecialArgs = {inherit inputs self;};
            home-manager.users.usu = import ./home/default.nix;
          }
        ];
      };
    };

    packages.x86_64-linux.shade = self.nixosConfigurations.shade.config.system.build.toplevel;
    packages.x86_64-linux.img-shade = self.nixosConfigurations.img-shade.config.system.build.toplevel;
  };
}
