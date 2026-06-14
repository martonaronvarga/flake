{pkgs, ...}: {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
      bell = "none";
      hideSearchHighlight = true;
      syntaxHighlighting = true;

      autocomplete.nvim-cmp.enable = true;
      assistant.copilot.enable = true;
      comments.comment-nvim.enable = true;
      dashboard.dashboard-nvim.enable = true;
      git.enable = true;
      globals.mapLeader = " ";
      minimap.codewindow.enable = true;
      notify.nvim-notify.enable = true;
      snippets.luasnip.enable = true;
      spellcheck.enable = true;
      telescope.enable = true;
      terminal.toggleterm.enable = true;
      treesitter.enable = true;

      options = {
        autoindent = true;
        termguicolors = true;
      };

      lsp = {
        enable = true;
        formatOnSave = true;
        lightbulb.enable = true;
        trouble.enable = true;
        presets.tailwindcss-language-server.enable = true;
      };

      extraPackages = [pkgs.fzf pkgs.ripgrep];
      extraPlugins = with pkgs.vimPlugins; {
        aerial = {
          package = aerial-nvim;
          setup = "require('aerial').setup {}";
        };
        harpoon = {
          package = harpoon;
          setup = "require('harpoon').setup {}";
          after = ["aerial"];
        };
      };

      languages = {
        enableDAP = true;
        enableExtraDiagnostics = true;
        enableFormat = true;
        enableTreesitter = true;
        bash.enable = true;
        clang.enable = true;
        css.enable = true;
        go.enable = true;
        html.enable = true;
        lua.enable = true;
        markdown.enable = true;
        nix.enable = true;
        python.enable = true;
        r.enable = true;
        rust.enable = true;
        sql.enable = true;
        svelte.enable = true;
        typescript.enable = true;
      };

      filetree.nvimTree = {
        enable = true;
        setupOpts = {
          git.enable = true;
          renderer = {
            add_trailing = true;
            icons = {};
          };
        };
      };

      statusline.lualine = {
        enable = true;
        icons.enable = true;
        theme = "auto";
      };

      extraLuaFiles = [
        ./neovim/noir.lua
      ];
    };
  };
}
