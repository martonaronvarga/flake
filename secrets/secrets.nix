let
  usu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
in {
  "usu.age".publicKeys = [usu];
  "aerc_client_id.age".publicKeys = [usu];
  "aerc_client_secret.age".publicKeys = [usu];
  "aerc_refresh_token.age".publicKeys = [usu];
}
