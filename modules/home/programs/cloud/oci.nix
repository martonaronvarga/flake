{config, ...}: {
  xdg.configFile = {
    "oci/config".source = config.lib.file.mkOutOfStoreSymlink "/run/agenix/oci-config";
    "oci/oci_private_key.pem".source = config.lib.file.mkOutOfStoreSymlink "/run/agenix/oci-private-key";
  };
}
