{ lib, config, pkgs, ... }: {

  nix.settings = {
    substituters = [
      "https://usu.cachix.org?priority=1"
      "https://cache.nixos.org?priority=2"

      "https://numtide.cachix.org?priority=3"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org?priority=4"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "usu.cachix.org-1:5jwkfmhQB89RUnXnSde4kN01awJGUqoBkqP0uRKPMFk="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };
}

