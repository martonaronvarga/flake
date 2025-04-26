{
  config,
  pkgs,
  ...
}: let
  theme = "ashenblack";
in {
  programs.helix = {
    enable = true;

    settings = {
      theme = theme;

      editor = {
        line-number = "absolute";
        mouse = true;
        true-color = true;
        auto-pairs = true;
        cursorline = true;
        completion-trigger-len = 1;
        rulers = [80];
        bufferline = "always";
        scrolloff = 8;
        statusline = {
          left = ["mode" "spinner" "file-name"];
          center = ["diagnostics"];
          right = ["position" "position-percentage" "file-encoding"];
        };
      };

      keys.normal = {
        "space" = {
          "w" = ":w";
          "q" = ":q";
          "x" = ":x";
          "c" = ":config-open";
          "r" = ":config-reload";
          "e" = ":open ~/.config/helix/config.toml";
          "f" = ":open ~/.config/helix";
        };
        "H" = "goto_previous_buffer";
        "L" = "goto_next_buffer";
        "U" = "redo";
      };

      editor.whitespace.render = {
        space = "none";
        tab = "all";
        newline = "none";
      };
    };

    languages = {
      language-server = {
        rust-analyzer = {
          command = "rust-analyzer";
        };

        pyright = {
          command = "pyright-langserver";
          args = ["--stdio"];
        };

        r-languageserver = {
          command = "R";
          args = ["--slave" "-e" "languageserver::run()"];
        };

        nil = {
          command = "nil";
        };
      };

      language = [
        {
          name = "rust";
          auto-format = true;
          formatter = {
            command = "rustfmt";
          };
          language-servers = ["rust-analyzer"];
        }

        {
          name = "python";
          auto-format = true;
          language-servers = ["pyright"];
        }

        {
          name = "r";
          language-servers = ["r-languageserver"];
        }

        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "alejandra";
            args = ["-"];
          };
          language-servers = ["nil"];
        }
      ];
    };

    themes = {
      "ashenblack" = let
        palette = {
          background = "#000000";
          text = "#b4b4b4";
          red_flame = "#C53030";
          red_glowing = "#DF6464";
          red_ember = "#B14242";
          orange_glow = "#D87C4A";
          orange_blaze = "#C4693D";
          orange_muted = "#6D3B22";
          orange_smolder = "#E49A44";
          orange_golden = "#E5A72A";
          golden_muted = "#6D4D0D";
          brown = "#89492a";
          brown_dark = "#322119";
          blue = "#4A8B8B";
          g_1 = "#e5e5e5";
          g_2 = "#d5d5d5";
          g_3 = "#b4b4b4";
          g_4 = "#a7a7a7";
          g_5 = "#949494";
          g_6 = "#737373";
          g_7 = "#535353";
          g_8 = "#323232";
          g_9 = "#212121";
          g_10 = "#1d1d1d";
          g_11 = "#191919";
          g_12 = "#151515";
        };
      in {
        # Syntax highlighting
        "attribute" = "${palette.g_4}";
        "type" = "${palette.blue}";
        "type.builtin" = "${palette.blue}";
        "type.parameter" = "${palette.orange_glow}";
        "type.enum.variant" = "${palette.orange_blaze}";
        "constructor" = "${palette.g_1}";
        "constant" = "${palette.orange_blaze}";
        "constant.builtin" = "${palette.blue}";
        "constant.character" = "{ fg = \"${palette.red_glowing}\"; modifiers = [ \"bold\" ]; }";
        "constant.character.escape" = "${palette.g_2}";
        "constant.numeric" = "${palette.blue}";
        "string" = "${palette.red_glowing}";
        "string.regexp" = "${palette.orange_glow}";
        "string.special" = "${palette.g_2}";
        "string.special.url" = "{ fg = \"${palette.red_glowing}\"; modifiers = [ \"bold\" ]; }";
        "string.special.path" = "{ fg = \"${palette.red_glowing}\"; modifiers = [ \"bold\" ]; }";
        "string.special.symbol" = "${palette.orange_smolder}";
        "comment" = "{ fg = \"${palette.g_6}\"; modifiers = [ \"italic\" ]; }";
        "comment.block.documentation" = "{ fg = \"${palette.g_5}\"; modifiers = [ \"italic\" ]; }";
        "variable" = "${palette.g_3}";
        "variable.parameter" = "{ fg = \"${palette.g_2}\"; modifiers = [ \"italic\" ]; }";
        "variable.builtin" = "${palette.blue}";
        "variable.other.member" = "{ fg = \"${palette.g_2}\"; }";
        "label" = "${palette.red_ember}";
        "punctuation" = "${palette.g_2}";
        "punctuation.special" = "${palette.orange_golden}";
        "punctuation.bracket" = "${palette.g_6}";
        "punctuation.delimiter" = "${palette.orange_smolder}";
        "keyword" = "${palette.red_ember}";
        "keyword.operator" = "${palette.orange_blaze}";
        "keyword.directive" = "{ fg = \"${palette.red_ember}\"; modifiers = [ \"italic\" ]; }";
        "keyword.storage.modifier" = "{ fg = \"${palette.red_ember}\"; modifiers = [ \"italic\" ]; }";
        "operator" = "${palette.orange_glow}";
        "function" = "{ fg = \"${palette.g_3}\"; modifiers = [ \"bold\" ]; }";
        "function.builtin" = "{ fg = \"${palette.g_3}\"; modifiers = [ \"bold\" \"italic\" ]; }";
        "function.macro" = "${palette.red_ember}";
        "tag" = "{ fg = \"${palette.orange_glow}\"; modifiers = [ \"italic\" ]; }";
        "namespace" = "{ fg = \"${palette.orange_glow}\"; modifiers = [ \"bold\" ]; }";
        "special" = "${palette.orange_smolder}";
        "markup.heading" = "{ fg = \"${palette.red_glowing}\"; modifiers = [ \"bold\" ]; }";
        "markup.list" = "${palette.orange_glow}";
        "markup.bold" = "{ modifiers = [ \"bold\" ]; }";
        "markup.italic" = "{ modifiers = [ \"italic\" ]; }";
        "markup.link.url" = "{ fg = \"${palette.red_glowing}\"; modifiers = [ \"italic\" \"underlined\" ]; }";
        "markup.link.text" = "${palette.red_ember}";
        "markup.raw" = "{ fg = \"${palette.g_2}\"; bg = \"${palette.g_10}\"; }";
        "markup.quote" = "{ modifiers = [ \"italic\" ]; }";
        "diff.plus" = "${palette.g_6}";
        "diff.minus" = "${palette.red_ember}";
        "diff.delta" = "${palette.brown}";

        # User interface
        "ui.background" = "{ fg = \"${palette.text}\"; bg = \"${palette.background}\"; }";
        "ui.linenr" = "{ fg = \"${palette.g_8}\"; }";
        "ui.linenr.selected" = "{ fg = \"${palette.g_6}\"; }";
        "ui.statusline" = "{ fg = \"${palette.g_3}\"; bg = \"${palette.g_9}\"; }";
        "ui.statusline.inactive" = "{ fg = \"${palette.g_5}\"; bg = \"${palette.g_10}\"; }";
        "ui.statusline.normal" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_blaze}\"; modifiers = [ \"bold\" ]; }";
        "ui.statusline.insert" = "{ fg = \"${palette.g_1}\"; bg = \"${palette.g_7}\"; modifiers = [ \"bold\" ]; }";
        "ui.statusline.select" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_golden}\"; modifiers = [ \"bold\" ]; }";
        "ui.popup" = "{ fg = \"${palette.text}\"; bg = \"${palette.g_10}\"; }";
        "ui.info" = "{ fg = \"${palette.orange_blaze}\"; bg = \"${palette.g_10}\"; }";
        "ui.window" = "{ fg = \"${palette.g_7}\"; }";
        "ui.help" = "{ fg = \"${palette.text}\"; bg = \"${palette.g_10}\"; modifiers = [ \"bold\" ]; }";
        "ui.bufferline" = "{ fg = \"${palette.text}\"; bg = \"${palette.background}\"; }";
        "ui.bufferline.active" = "{ fg = \"${palette.g_2}\"; bg = \"${palette.g_10}\"; underline = { color = \"${palette.orange_blaze}\"; style = \"line\"; }; }";
        "ui.bufferline.background" = "{ bg = \"${palette.background}\"; }";
        "ui.text" = "${palette.text}";
        "ui.text.focus" = "{ fg = \"${palette.g_2}\"; bg = \"${palette.g_10}\"; underline = { color = \"${palette.red_ember}\"; style = \"line\"; }; modifiers = [ \"bold\" ]; }";
        "ui.text.inactive" = "{ fg = \"${palette.g_7}\"; }";
        "ui.text.directory" = "{ fg = \"${palette.red_ember}\"; }";
        "ui.virtual" = "${palette.g_5}";
        "ui.virtual.ruler" = "{ bg = \"cursorline\"; }";
        "ui.virtual.whitespace" = "${palette.g_7}";
        "ui.virtual.indent-guide" = "${palette.g_7}";
        "ui.virtual.wrap" = "${palette.g_7}";
        "ui.virtual.inlay-hint" = "{ fg = \"${palette.g_6}\"; modifiers = [ \"italic\" ]; }";
        "ui.virtual.jump-label" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_blaze}\"; modifiers = [ \"bold\" ]; }";
        "ui.selection" = "{ bg = \"${palette.brown_dark}\"; }";
        "ui.cursor.normal" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_muted}\"; }";
        "ui.cursor.insert" = "{ fg = \"${palette.background}\"; bg = \"${palette.g_7}\"; }";
        "ui.cursor.select" = "{ fg = \"${palette.background}\"; bg = \"${palette.golden_muted}\"; }";
        "ui.cursor.primary.normal" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_blaze}\"; modifiers = [ \"bold\" ]; }";
        "ui.cursor.primary.insert" = "{ fg = \"${palette.background}\"; bg = \"${palette.g_3}\"; modifiers = [ \"bold\" ]; }";
        "ui.cursor.primary.select" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_golden}\"; modifiers = [ \"bold\" ]; }";
        "ui.cursor.match" = "{ fg = \"${palette.orange_smolder}\"; modifiers = [ \"underlined\" ]; }";
        "ui.cursorline.primary" = "{ bg = \"cursorline\"; }";
        "ui.cursorline" = "{ bg = \"${palette.g_12}\"; }";
        "ui.highlight" = "{ fg = \"${palette.orange_blaze}\"; bg = \"cursorline\"; underline = { color = \"${palette.red_ember}\"; style = \"line\"; }; modifiers = [ \"bold\" ]; }";
        "ui.menu" = "{ fg = \"${palette.g_2}\"; bg = \"${palette.g_10}\"; }";
        "ui.menu.selected" = "{ fg = \"${palette.background}\"; bg = \"${palette.orange_blaze}\"; modifiers = [ \"bold\" ]; }";
        "diagnostic.error" = "{ underline = { color = \"${palette.red_flame}\"; style = \"curl\"; }; }";
        "diagnostic.warning" = "{ underline = { color = \"${palette.orange_golden}\"; style = \"curl\"; }; }";
        "diagnostic.info" = "{ underline = { color = \"${palette.g_4}\"; style = \"dotted\"; }; }";
        "diagnostic.hint" = "{ underline = { color = \"${palette.g_5}\"; style = \"dotted\"; }; }";
        "diagnostic.unnecessary" = "{ modifiers = [ \"dim\" ]; }";
        error = "{ fg = \"${palette.red_flame}\"; bg = \"${palette.g_10}\"; }";
        warning = "{ fg = \"${palette.orange_golden}\"; bg = \"${palette.g_10}\"; }";
        info = "{ fg = \"${palette.g_3}\"; bg = \"${palette.g_10}\"; }";
        hint = "{ fg = \"${palette.g_4}\"; bg = \"${palette.g_10}\"; }";
      };
    };
  };

  home.packages = with pkgs; [
    helix
    nil
    rust-analyzer
    rustfmt
    pyright
    R
    tree-sitter
  ];
}
