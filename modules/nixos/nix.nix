{
  config,
  lib,
  ...
}: {
  options.local.flakePath = lib.mkOption {
    type = lib.types.str;
    default = "/persist/etc/nixos";
    description = "Canonical local checkout path used by nh for this host.";
  };

  config = {
    programs.nh = {
      enable = true;
      flake = config.local.flakePath;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    systemd.tmpfiles.rules = lib.mkIf (config.local.flakePath == "/persist/etc/nixos") [
      "d /persist/etc/nixos 0755 root root -"
    ];

    nix = {
      gc.automatic = false;

      settings = {
        auto-optimise-store = true;
        builders-use-substitutes = true;
        experimental-features = ["nix-command" "flakes"];
        accept-flake-config = true;
        use-xdg-base-directories = true;
        warn-dirty = false;

        keep-derivations = true;
        keep-outputs = true;

        trusted-users = ["@wheel" "usu"];

        substituters = [
          "https://usu.cachix.org?priority=1"
          "https://cache.nixos.org?priority=2"

          "https://numtide.cachix.org?priority=3"
          "https://nix-community.cachix.org?priority=4"
          "https://hyprland.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "usu.cachix.org-1:5jwkfmhQB89RUnXnSde4kN01awJGUqoBkqP0uRKPMFk="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        ];
      };
    };
  };
}
