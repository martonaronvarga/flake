{
  config,
  lib,
  ...
}: let
  cfg = config.local.agenix;

  mkAgeSecret = _name: secret:
    {
      inherit (secret) file mode owner;
    }
    // lib.optionalAttrs (secret.group != null) {inherit (secret) group;}
    // lib.optionalAttrs (secret.path != null) {inherit (secret) path;};
in {
  options.local.agenix = {
    identityPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Host-local age identity paths used by agenix.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          file = lib.mkOption {
            type = lib.types.path;
            description = "Encrypted age file for this secret.";
          };

          owner = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Runtime owner of the decrypted secret.";
          };

          group = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional runtime group of the decrypted secret.";
          };

          mode = lib.mkOption {
            type = lib.types.str;
            default = "0400";
            description = "Runtime mode of the decrypted secret.";
          };

          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional explicit runtime path for the decrypted secret.";
          };
        };
      });
      default = {};
      description = "Host-local agenix secrets.";
    };
  };

  config = {
    age.identityPaths = cfg.identityPaths;
    age.secrets = lib.mapAttrs mkAgeSecret cfg.secrets;
  };
}
