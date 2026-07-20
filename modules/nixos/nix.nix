{
  config,
  lib,
  ...
}: {
  options.local = {
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "/persist/etc/nixos";
      description = "Canonical local checkout path used by nh for this host.";
    };
    nixPolicy = {
      acceptFlakeConfig = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      trustedUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["root"];
      };
      extraSubstituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      extraTrustedPublicKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };
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
        accept-flake-config = config.local.nixPolicy.acceptFlakeConfig;
        use-xdg-base-directories = true;
        warn-dirty = false;

        keep-derivations = true;
        keep-outputs = true;

        trusted-users = config.local.nixPolicy.trustedUsers;

        substituters =
          [
            "https://usu.cachix.org?priority=1"
            "https://cache.nixos.org?priority=2"
          ]
          ++ config.local.nixPolicy.extraSubstituters;

        trusted-public-keys =
          [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "usu.cachix.org-1:5jwkfmhQB89RUnXnSde4kN01awJGUqoBkqP0uRKPMFk="
          ]
          ++ config.local.nixPolicy.extraTrustedPublicKeys;
      };
    };
  };
}
