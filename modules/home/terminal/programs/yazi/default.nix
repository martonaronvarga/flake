{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # ./theme/filetype.nix
    # ./theme/icons.nix
    # ./theme/manager.nix
    # ./theme/status.nix
  ];

  # general file info
  home.packages = [pkgs.exiftool];

  # yazi file manager
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

    enableBashIntegration = config.programs.bash.enable or false;
    enableZshIntegration = config.programs.zsh.enable or false;

    settings = {
      mgr = {
        #manager = {
        layout = [1 4 3];
        sort_by = "alphabetical";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_hidden = false;
        show_symlink = true;
      };

      preview = {
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = config.xdg.cacheHome;
      };
    };
    flavors = let
      rawAshenFlavor = pkgs.fetchFromGitHub {
        owner = "ficd0";
        repo = "ashen";
        sparseCheckout = ["ashen.yazi"];
        rev = "2da901f3ce7f233c7a2437cb2b824afd2a01f2aa";
        hash = "sha256-qDL7LNOwL2RistiiEZkdzOUY7vHZs71i8Kb+/jb2pr0=";
      };

      ashenFlavor = pkgs.runCommand "flatten" {} ''
        mkdir -p $out
        cp -r ${rawAshenFlavor}/ashen.yazi/* $out/
      '';
    in {
      ashen = ashenFlavor;
    };

    theme.flavor = {
      dark = "ashen";
      light = "ashen";
    };
  };
}
