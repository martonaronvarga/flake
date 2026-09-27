# Convenience entry point for Colmena.
# Usage:
#   colmena apply --on dusk
let
  flake = builtins.getFlake (toString ./.);
in
  flake.colmenaHive
