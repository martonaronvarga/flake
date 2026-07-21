{
  inventory,
  pkgs,
  ...
}: let
  inherit (inventory) domain;
in {
  home.packages = [pkgs.iamb];

  xdg.configFile."iamb/config.toml".text = ''
    default_profile = "usu"

    [profiles.usu]
    user_id = "@usu:${domain}"
    url = "https://matrix.${domain}"

    [settings]
    message_user_color = false
    username_display = "displayname"

    [settings.image_preview]
    protocol.type = "kitty"
    size = { height = 12, width = 60 }
  '';
}
