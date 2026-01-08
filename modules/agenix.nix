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
    aerc-client-id = {
      file = toString ../secrets/aerc_client_id.age;
      owner = "usu";
      mode = "0400";
      path = "/run/agenix/aerc-client-id";
    };
    aerc-client-secret = {
      file = toString ../secrets/aerc_client_secret.age;
      owner = "usu";
      mode = "0400";
      path = "/run/agenix/aerc-client-secret";
    };
    aerc-refresh-token = {
      file = toString ../secrets/aerc_refresh_token.age;
      owner = "usu";
    };
  };
  age.identityPaths = ["/persist/home/usu/.ssh/id_ed25519"];
}
