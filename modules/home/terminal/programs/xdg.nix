{
  config,
  pkgs,
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

  image = xdgAssociations "image" imageViewer ["png" "svg" "jpeg" "jpg" "gif" "webp"];
  video = xdgAssociations "video" videoPlayer ["mp4" "avi" "mkv" "webm"];
  audio = xdgAssociations "audio" audioPlayer ["mp3" "flac" "wav" "aac" "ogg"];
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

  # XDG MIME types; values omit the .desktop suffix until the final normalization.
  associations = builtins.mapAttrs (_: v: map (e: "${e}.desktop") v) ({
      "application/pdf" = ["org.pwmt.zathura"];
      "application/epub+zip" = ["org.pwmt.zathura"];
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
    cacheHome = "${config.home.homeDirectory}/.cache";

    mimeApps = {
      enable = true;
      defaultApplications = associations;
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/music";
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = "${config.home.homeDirectory}/public";
      templates = "${config.home.homeDirectory}/templates";
      videos = "${config.home.homeDirectory}/videos";
      extraConfig = {
        SCREENSHOTS = "${config.xdg.userDirs.pictures}/screenshots";
      };
    };
  };

  home.packages = [
    # used by `gio open` and xdg-utils
    (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      kitty "$@"
    '')
    pkgs.xdg-utils
    pkgs.feh
  ];
}
