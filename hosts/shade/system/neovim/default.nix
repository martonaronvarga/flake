{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;
        autocomplete.nvim-cmp.enable = true;
        lsp.enable = true;
        assistant.copilot.enable = true;
        bell = "none";
        options.termguicolors = true;
        options.autoindent = true;
        comments.comment-nvim.enable = true;
        dashboard.dashboard-nvim.enable = true;
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

        git.enable = true;
        hideSearchHighlight = true;

        languages = {
          enableDAP = true;
          enableExtraDiagnostics = true;
          enableFormat = true;
          enableTreesitter = true;

          bash = {
            enable = true;
          };

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
          tailwind.enable = true;
          ts.enable = true;
        };

        globals.mapLeader = " ";
        lsp.formatOnSave = true;
        lsp.lightbulb.enable = true;
        lsp.trouble.enable = true;

        minimap.codewindow.enable = true;
        notify.nvim-notify.enable = true;

        snippets.luasnip.enable = true;
        spellcheck.enable = true;

        statusline.lualine.enable = true;
        statusline.lualine.icons.enable = true;
        statusline.lualine.theme = "auto";

        syntaxHighlighting = true;

        telescope.enable = true;
        terminal.toggleterm.enable = true;

        treesitter.enable = true;

        # custom theme vim -noir
        extraLuaFiles = [
          (builtins.path {path = ./noir.lua;})
        ];
      };
    };
  };
}
