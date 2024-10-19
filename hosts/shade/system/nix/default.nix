{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nixpkgs.nix
    ./substituters.nix
  ];

  environment.systemPackages = [pkgs.git];

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      accept-flake-config = true;
      use-xdg-base-directories = true;

      keep-derivations = true;
      keep-outputs = true;

      trusted-users = ["root" "wheel"];
    };
  };
}
