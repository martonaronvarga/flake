{
  description = "martonaronvarga's nix infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    website.url = "git+https://git.martonaronvarga.dev/usu/martonaronvarga.dev.git?ref=main";

    utils.url = "github:zimbatm/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

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
        aquamarine.follows = "hyprland/aquamarine";
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
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: let
      lib = import ./lib {
        inherit (inputs.nixpkgs) lib;
        inherit inputs withSystem;
      };
    in {
      imports = [
        ./parts/hosts.nix
        ./parts/colmena.nix
        ./parts/devshell.nix
        ./parts/topology.nix
      ];

      systems = ["x86_64-linux" "aarch64-linux"];

      flake = {
        inherit lib;
      };

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        nixpkgsLib = inputs.nixpkgs.lib;
        inherit (nixpkgsLib) fileset;
        nixFiles = fileset.toSource {
          root = ./.;
          fileset = fileset.unions [
            ./flake.nix
            ./hosts
            ./lib
            ./modules
            ./parts
            ./profiles
            ./secrets/secrets.nix
          ];
        };
        mkCheck = name: package: command:
          pkgs.runCommandLocal name {nativeBuildInputs = [package];} ''
            ${command} ${nixFiles}
            touch $out
          '';
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.nix-topology.overlays.default];
          config.allowUnfree = true;
        };

        formatter = pkgs.alejandra;

        checks = nixpkgsLib.optionalAttrs (system == "x86_64-linux") {
          alejandra = mkCheck "alejandra-check" pkgs.alejandra "alejandra --check";
          statix = mkCheck "statix-check" pkgs.statix "statix check";
          deadnix = mkCheck "deadnix-check" pkgs.deadnix "deadnix --fail";
        };
      };
    });
}
