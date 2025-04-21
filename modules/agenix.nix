{
  pkgs,
  lib,
  config,
  ...
}: {
  age.secrets = {
    usu = {
      file = toString ../secrets/usu.age;
      owner = "usu";
      mode = "600";
    };
  };
  age.identityPaths = [ "/persist/home/usu/.ssh/id_ed25519" ];
}
