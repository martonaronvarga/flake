let
  usu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
  dusk = "age1a2h0y24s33xvqc2w72hy5q20ptpqhf9v4n8uxpnnr3havxqsec0qj4f9mu";
  gloam = "age1ge9qjnqe6qc904yf6h9unjzvsc30kh9q0cfln5j8dl2tre0jqdfqhyy26j";
in {
  "usu.age".publicKeys = [usu];
  "usu_password_hash.age".publicKeys = [usu dusk];
  "aerc_client_id.age".publicKeys = [usu];
  "aerc_client_secret.age".publicKeys = [usu];
  "dusk_wg_private_key.age".publicKeys = [usu dusk];
  "forgejo_mailer_password.age".publicKeys = [usu dusk];
  "gloam_wg_private_key.age".publicKeys = [usu gloam];
  "grafana_admin_password.age".publicKeys = [usu dusk];
  "grafana_secret_key.age".publicKeys = [usu dusk];
  "oci_config.age".publicKeys = [usu];
  "oci_private_key.age".publicKeys = [usu];
  "restic_shade_password.age".publicKeys = [usu dusk];
  "restic_external_password.age".publicKeys = [usu dusk];
  "shade_wg_private_key.age".publicKeys = [usu];
  "shade_dusk_builder_key.age".publicKeys = [usu];
  "vaultwarden_env.age".publicKeys = [usu dusk];
  "forgejo_runner_token.age".publicKeys = [usu dusk];
}
