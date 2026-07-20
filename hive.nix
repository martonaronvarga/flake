# Convenience entry point for Colmena.
# This keeps `nix flake check` free of unknown custom outputs while allowing:
#   colmena apply --on dusk
let
  flake = builtins.getFlake (toString ./.);
in
  flake.legacyPackages.x86_64-linux.colmenaHive
