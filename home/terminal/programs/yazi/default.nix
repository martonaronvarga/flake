{
  config,
  pkgs,
  lib,
  inputs,
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
        owner = "ficcdaf";
        repo = "ashen";
        sparseCheckout = ["ashen.yazi"];
        rev = "7f8cf4a0db595d0a573ed4ac63e69d6fff638a7e";
        hash = "sha256-JzdO1kNePzIcMPchKHYxQygeAvonOVWn9m5uCr1OJqg=";
      };

      ashenFlavor = pkgs.runCommand "flatten" {} ''
        mkdir -p $out
        cp -r ${rawAshenFlavor}/ashen.yazi/* $out/
      '';
    in {
      ashen = ashenFlavor;
    };

    theme = {
      flavor = {
        dark = "ashen";
        light = "ashen";
      };
    };
  };
}
