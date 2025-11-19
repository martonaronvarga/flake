{
  config,
  pkgs,
  lib,
  ...
}: let
  browser = ["firefox"];
  imageViewer = ["feh"];
  videoPlayer = ["vlc"];
  audioPlayer = ["vlc"];

  xdgAssociations = type: program: list:
    builtins.listToAttrs (map (e: {
        name = "${type}/${e}";
        value = program;
      })
      list);

  image = xdgAssociations "image" imageViewer ["png" "svg" "jpeg" "gif"];
  video = xdgAssociations "video" videoPlayer ["mp4" "avi" "mkv"];
  audio = xdgAssociations "audio" audioPlayer ["mp3" "flac" "wav" "aac"];
  browserTypes =
    (xdgAssociations "application" browser [
      "json"
      "x-extension-htm"
      "x-extension-html"
      "x-extension-shtml"
      "x-extension-xht"
      "x-extension-xhtml"
    ])
    // (xdgAssociations "x-scheme-handler" browser [
      "about"
      "ftp"
      "http"
      "https"
      "unknown"
    ]);

  # XDG MIME types
  associations = builtins.mapAttrs (_: v: (map (e: "${e}.desktop") v)) ({
      "application/pdf" = ["zathura"];
      "text/html" = browser;
      "text/plain" = ["hx"];
      "inode/directory" = ["yazi"];
    }
    // image
    // video
    // audio
    // browserTypes);
in {
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.local/cache";

    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        common.default = ["gtk"];
        common."org.freedesktop.portal.OpenURI" = ["gtk"];
        hyprland = {
          default = ["hyprland" "gtk"];
          "org.freedesktop.portal.impl.portal.Screenshot" = ["hyprland"];
          "org.freedesktop.portal.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktip.portal.impl.portal.OpenURI" = ["gtk"];
        };
      };

      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    mimeApps = {
      enable = true;
      defaultApplications = associations;
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/screenshots";
      };
    };
  };

  # Correctly define home packages
  home.packages = [
    # used by `gio open` and xdg-utils
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      kitty "$@"
    '')
    pkgs.xdg-utils
    pkgs.feh
  ];
}
