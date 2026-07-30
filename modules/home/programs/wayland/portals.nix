{
  config,
  pkgs,
  ...
}: let
  yaziWrapper = pkgs.writeShellScript "yazi-portal-wrapper" ''
    set -eu

    directory="$2"
    save="$3"
    path="$4"
    out="$5"

    if [[ "$save" == 1 ]]; then
      chooser_args=(--chooser-file="$out" "$path")
    elif [[ "$directory" == 1 ]]; then
      chooser_args=(--chooser-file="$out" --cwd-file="$out.1" "$path")
    else
      chooser_args=(--chooser-file="$out" "$path")
    fi

    ${pkgs.kitty}/bin/kitty \
      --class termfilechooser \
      --title "Yazi file chooser" \
      ${config.programs.yazi.package}/bin/yazi "''${chooser_args[@]}"

    if [[ "$directory" == 1 ]]; then
      if [[ ! -s "$out" && -s "$out.1" ]]; then
        ${pkgs.coreutils}/bin/cat "$out.1" >"$out"
      fi
      ${pkgs.coreutils}/bin/rm -f "$out.1"
    fi
  '';
in {
  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${yaziWrapper}
    default_dir=$HOME
    create_help_file=0
    open_mode=suggested
    save_mode=suggested
  '';
}
