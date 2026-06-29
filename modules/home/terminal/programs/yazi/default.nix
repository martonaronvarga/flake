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
    flavors = {
      kitty-mono = pkgs.writeTextDir "flavor.toml" ''
        [manager]
        cwd = { fg = "#ffffff", bold = true }
        hovered = { fg = "#ffffff", bg = "#1a1a1a", bold = true }
        preview_hovered = { fg = "#ffffff", bg = "#1a1a1a", bold = true }
        find_keyword = { fg = "#ffffff", bold = true, italic = true, underline = true }
        find_position = { fg = "#888888", bg = "reset", bold = true, italic = true }
        marker_copied = { fg = "#d0d0d0", bg = "#d0d0d0" }
        marker_cut = { fg = "#888888", bg = "#888888" }
        marker_marked = { fg = "#ffffff", bg = "#ffffff" }
        marker_selected = { fg = "#ffffff", bg = "#ffffff" }
        tab_active = { fg = "#ffffff", bg = "#000000", bold = true }
        tab_inactive = { fg = "#888888", bg = "#000000" }
        tab_width = 1
        count_copied = { fg = "#000000", bg = "#d0d0d0" }
        count_cut = { fg = "#000000", bg = "#888888" }
        count_selected = { fg = "#000000", bg = "#ffffff" }
        border_symbol = "│"
        border_style = { fg = "#888888" }

        [mode]
        normal_main = { fg = "#000000", bg = "#ffffff", bold = true }
        normal_alt = { fg = "#d0d0d0", bg = "#000000" }
        select_main = { fg = "#000000", bg = "#d0d0d0", bold = true }
        select_alt = { fg = "#d0d0d0", bg = "#000000" }
        unset_main = { fg = "#000000", bg = "#888888", bold = true }
        unset_alt = { fg = "#888888", bg = "#000000" }

        [status]
        separator_open = ""
        separator_close = ""
        progress_label = { fg = "#ffffff", bold = true }
        progress_normal = { fg = "#ffffff", bg = "#1a1a1a" }
        progress_error = { fg = "#ffffff", bg = "#1a1a1a", bold = true }
        perm_sep = { fg = "#888888", bold = true }
        perm_type = { fg = "#888888" }
        perm_read = { fg = "#d0d0d0", bold = true }
        perm_write = { fg = "#ffffff", bold = true }
        perm_exec = { fg = "#ffffff", bold = true }

        [pick]
        border = { fg = "#888888" }
        active = { fg = "#ffffff", bold = true }
        inactive = {}

        [input]
        border = { fg = "#888888" }
        title = {}
        value = {}
        selected = { reversed = true }

        [completion]
        border = { fg = "#888888" }

        [tasks]
        border = { fg = "#888888" }
        title = {}
        hovered = { fg = "#ffffff", underline = true }

        [which]
        mask = { bg = "#000000" }
        cand = { fg = "#ffffff" }
        rest = { fg = "#d0d0d0" }
        desc = { fg = "#888888" }
        separator = "  "
        separator_style = { fg = "#888888" }

        [help]
        on = { fg = "#ffffff" }
        run = { fg = "#d0d0d0" }
        desc = { fg = "#888888" }
        hovered = { reversed = true, bold = true }
        footer = { fg = "#ffffff", bg = "#000000" }

        [notify]
        title_info = { fg = "#d0d0d0" }
        title_warn = { fg = "#ffffff", bold = true }
        title_error = { fg = "#ffffff", bold = true }

        [filetype]
        rules = [
          { name = "*/", fg = "#ffffff", bold = true },
          { name = "*", fg = "#d0d0d0" },
        ]
      '';
    };

    theme.flavor = {
      dark = "kitty-mono";
      light = "kitty-mono";
    };
  };
}
