let
  usu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
  dusk = "age1a2h0y24s33xvqc2w72hy5q20ptpqhf9v4n8uxpnnr3havxqsec0qj4f9mu";
in {
  "usu.age".publicKeys = [usu];
  "usu_password_hash.age".publicKeys = [usu dusk];
  "aerc_client_id.age".publicKeys = [usu];
  "aerc_client_secret.age".publicKeys = [usu];
}
