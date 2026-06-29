{
  config,
  pkgs,
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
      black = "#000000";
      white = "#ffffff";
    in {
      kitty-mono = pkgs.writeTextDir "flavor.toml" ''
        [manager]
        cwd = { fg = "${white}", bold = true }
        hovered = { fg = "${black}", bg = "${white}", bold = true }
        preview_hovered = { fg = "${black}", bg = "${white}", bold = true }
        find_keyword = { fg = "${black}", bg = "${white}", bold = true, italic = true, underline = true }
        find_position = { fg = "${white}", bg = "${black}", bold = true, italic = true }
        marker_copied = { fg = "${white}", bg = "${white}" }
        marker_cut = { fg = "${white}", bg = "${white}" }
        marker_marked = { fg = "${white}", bg = "${white}" }
        marker_selected = { fg = "${white}", bg = "${white}" }
        tab_active = { fg = "${black}", bg = "${white}", bold = true }
        tab_inactive = { fg = "${white}", bg = "${black}" }
        tab_width = 1
        count_copied = { fg = "${black}", bg = "${white}" }
        count_cut = { fg = "${black}", bg = "${white}" }
        count_selected = { fg = "${black}", bg = "${white}" }
        border_symbol = "│"
        border_style = { fg = "${white}" }

        [mode]
        normal_main = { fg = "${black}", bg = "${white}", bold = true }
        normal_alt = { fg = "${white}", bg = "${black}" }
        select_main = { fg = "${black}", bg = "${white}", bold = true }
        select_alt = { fg = "${white}", bg = "${black}" }
        unset_main = { fg = "${black}", bg = "${white}", bold = true }
        unset_alt = { fg = "${white}", bg = "${black}" }

        [status]
        separator_open = ""
        separator_close = ""
        progress_label = { fg = "${white}", bold = true }
        progress_normal = { fg = "${black}", bg = "${white}" }
        progress_error = { fg = "${black}", bg = "${white}", bold = true }
        perm_sep = { fg = "${white}", bold = true }
        perm_type = { fg = "${white}" }
        perm_read = { fg = "${white}", bold = true }
        perm_write = { fg = "${white}", bold = true }
        perm_exec = { fg = "${white}", bold = true }

        [pick]
        border = { fg = "${white}" }
        active = { fg = "${black}", bg = "${white}", bold = true }
        inactive = {}

        [input]
        border = { fg = "${white}" }
        title = {}
        value = {}
        selected = { reversed = true }

        [completion]
        border = { fg = "${white}" }

        [tasks]
        border = { fg = "${white}" }
        title = {}
        hovered = { fg = "${black}", bg = "${white}", underline = true }

        [which]
        mask = { bg = "${black}" }
        cand = { fg = "${white}" }
        rest = { fg = "${white}" }
        desc = { fg = "${white}" }
        separator = "  "
        separator_style = { fg = "${white}" }

        [help]
        on = { fg = "${white}" }
        run = { fg = "${white}" }
        desc = { fg = "${white}" }
        hovered = { reversed = true, bold = true }
        footer = { fg = "${white}", bg = "${black}" }

        [notify]
        title_info = { fg = "${white}" }
        title_warn = { fg = "${white}", bold = true }
        title_error = { fg = "${white}", bold = true }

        [filetype]
        rules = [
          { url = "*/", fg = "${white}", bold = true },
          { url = "*", fg = "${white}" },
        ]
      '';
    };

    theme.flavor = {
      dark = "kitty-mono";
      light = "kitty-mono";
    };
  };
}
