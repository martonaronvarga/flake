{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  hyprpaper = inputs.hyprpaper.packages.${system}.hyprpaper;
  wallpapers = {
    zeros = builtins.path {
      path = ../../../../assets/wallpapers/zeros.png;
      name = "zeros-wallpaper";
    };
    topographic-1 = builtins.path {
      path = ../../../../assets/wallpapers/topographic_wallpaper_1.jpg;
      name = "topographic-wallpaper-1";
    };
    topographic-2 = builtins.path {
      path = ../../../../assets/wallpapers/topographic_wallpaper_2.jpg;
      name = "topographic-wallpaper-2";
    };
  };

  hyprpaperLauncher = pkgs.writeShellApplication {
    name = "start-hyprpaper";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      state_directory="''${XDG_STATE_HOME:-$HOME/.local/state}/wayland-appearance"
      selection_file="$state_directory/wallpaper"
      selection="zeros"
      if [[ -r "$selection_file" ]]; then
        selection="$(<"$selection_file")"
      fi

      case "$selection" in
        zeros) wallpaper=${lib.escapeShellArg (toString wallpapers.zeros)} ;;
        shade)
          selection="zeros"
          wallpaper=${lib.escapeShellArg (toString wallpapers.zeros)}
          install -d -m 0700 "$state_directory"
          printf '%s\n' "$selection" >"$selection_file"
          ;;
        topographic-1) wallpaper=${lib.escapeShellArg (toString wallpapers.topographic-1)} ;;
        topographic-2) wallpaper=${lib.escapeShellArg (toString wallpapers.topographic-2)} ;;
        *) wallpaper=${lib.escapeShellArg (toString wallpapers.zeros)} ;;
      esac

      runtime_config="''${XDG_RUNTIME_DIR:?}/hyprpaper.conf"
      umask 077
      printf 'splash = false\nipc = true\nwallpaper {\n  monitor =\n  path = %s\n  fit_mode = cover\n}\n' \
        "$wallpaper" >"$runtime_config"
      exec ${lib.getExe hyprpaper} --config "$runtime_config"
    '';
  };

  previewWallpaper = pkgs.writeShellApplication {
    name = "preview-wallpaper";
    runtimeInputs = [
      pkgs.gnused
      pkgs.kitty
    ];
    text = ''
      kitten icat \
        --clear \
        --transfer-mode=stream \
        --unicode-placeholder \
        --stdin=no \
        --place="''${FZF_PREVIEW_COLUMNS:?}x''${FZF_PREVIEW_LINES:?}@0x0" \
        "$1" | sed '$d'
    '';
  };

  selectWallpaper = pkgs.writeShellApplication {
    name = "select-wallpaper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kitty
      pkgs.systemd
    ];
    text = ''
      if [[ "''${1:-}" != "--menu" ]]; then
        exec kitty --class wallpaper-selector --title "Select wallpaper" \
          "$0" --menu
      fi

      selection="$({
        printf 'Zeros\tzeros\t%s\n' ${lib.escapeShellArg (toString wallpapers.zeros)}
        printf 'Topographic 1\ttopographic-1\t%s\n' ${lib.escapeShellArg (toString wallpapers.topographic-1)}
        printf 'Topographic 2\ttopographic-2\t%s\n' ${lib.escapeShellArg (toString wallpapers.topographic-2)}
      } | env -u FZF_DEFAULT_OPTS_FILE FZF_DEFAULT_OPTS= \
        ${lib.getExe config.programs.fzf.package} \
        --height=100% \
        --layout=reverse \
        --cycle \
        --border \
        --info=inline \
        --prompt='>' \
        --scrollbar='|' \
        --separator='-' \
        --no-bold \
        --pointer='>' \
        --marker='*' \
        --color='bg:#000000,bg+:#1a1a1a,fg:#d0d0d0,fg+:#ffffff,hl:#ffffff,hl+:#ffffff,border:#333333,label:#aaaaaa,info:#aaaaaa,header:#aaaaaa,prompt:#d0d0d0,pointer:#ffffff,marker:#ffffff,spinner:#aaaaaa,query:#ffffff,gutter:#000000' \
        --delimiter=$'\t' \
        --with-nth=1 \
        --header='enter: apply  esc: cancel' \
        --preview='${lib.getExe previewWallpaper} {3}' \
        --preview-window='down,70%,border-top')" || exit 0

      choice="$(cut -f2 <<<"$selection")"
      case "$choice" in
        zeros|topographic-1|topographic-2) ;;
        *) exit 1 ;;
      esac

      state_directory="''${XDG_STATE_HOME:-$HOME/.local/state}/wayland-appearance"
      install -d -m 0700 "$state_directory"
      printf '%s\n' "$choice" >"$state_directory/wallpaper"
      systemctl --user restart hyprpaper.service
    '';
  };
in {
  home.packages = [selectWallpaper];

  systemd.user.services.hyprpaper = {
    Unit = {
      Description = "Compositor-independent wallpaper service";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = lib.getExe hyprpaperLauncher;
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
