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
        shell = ["zsh" "-c"];
        line-number = "absolute";
        mouse = true;
        true-color = true;
        color-modes = true;
        undercurl = true;
        auto-pairs = true;
        cursorline = true;
        gutters = ["diagnostics" "line-numbers" "spacer" "diff"];
        auto-format = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "block";
        };
        completion-trigger-len = 1;
        completion-replace = true;
        rulers = [80];
        bufferline = "always";
        scrolloff = 8;
        statusline = {
          left = ["mode" "selections" "spinner" "file-name"];
          center = ["diagnostics"];
          right = ["file-encoding" "file-type" "position" "position-percentage" "file-encoding"];
        };
        indent-guides = {
          render = true;
          character = "▏";
          skip-levels = 1;
        };
      };

      keys.normal = {
        "space" = {
          "f" = "file_picker";
          "S" = "global_search";
          "w" = ":w";
          "q" = ":q";
          "x" = ":x";
          "n" = {
            "n" = ":lsp-execute-command zk.newNote";
            "l" = ":lsp-execute-comand zk.insertLink";
            "b" = ":lsp-execute-command zk.showBacklinks";
          };
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
        bash-language-server = {
          command = "bash-language-server";
          args = ["start"];
        };

        clangd = {
          command = "clangd";
        };
        idris2-lsp = {
          command = "idris2-lsp";
        };
        julia = {
          comand = "julia";
          timeout = 60;
          args = ["--startup-file=no" "--history-file=no" "--quiet" "-e" "using LanguageServer;" "runserver()"];
        };
        rust-analyzer = {
          command = "rust-analyzer";
          config.rust-analyzer = {
            "inlayHints.closingBraceHints.minLines" = 10;
            "inlayHints.closureReturnTypeHints.enable" = "with_block";
            "inlayHints.discriminantHints.enable" = "fieldless";
            files = {
              watcher = "server";
            };
            check = {
              command = "clippy";
            };
            checkOnSave.command = "clippy";
            procMacro.enable = true;
            lens = {
              references = true;
              methodReferences = true;
            };
            completion.autoimport.enable = true;
            experimental.procAttrMacros = true;
            cargo = {
              loadOutDirsFromCheck = true;
              features = "all";
            };
          };
        };

        typescript-language-server = {
          command = "typescript-language-server";
          args = ["--stdio"];
          config.hostInfo = "helix";
        };

        svelteserver = {
          command = "svelteserver";
          args = ["--stdio"];
        };

        pyright = {
          command = "pyright-langserver";
          args = ["--stdio"];
        };

        ruff = {
          command = "ruff";
          args = ["server"];
        };

        r-languageserver = {
          command = "R";
          args = ["--slave" "-e" "languageserver::run()"];
        };

        nil = {
          command = "nil";
        };

        marksman = {
          command = "marksman";
          args = ["server"];
        };

        texlab = {
          command = "texlab";
        };

        tailwindcss-ls = {
          command = "tailwindcss-language-server";
          args = ["--stdio"];
        };
      };

      language = [
        {
          name = "bash";
          scope = "source.bash";
          injection-regex = "(shell|bash|zsh|sh)";
          file-types = [
            "sh"
            "bash"
            "zsh"
            "zshenv"
            "zshrc"
            "Renviron"
            {glob = ".Renviron";}
          ];
          shebangs = ["sh" "bash" "zsh"];
          comment-token = "#";
          language-servers = ["bash-language-server"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = "${pkgs.shfmt}/bin/shfmt";
          args = ["-i" "4" "-s" "-ci" "-sr"];
        }
        {
          name = "rust";
          scope = "source.rust";
          injection-regex = "rs|rust";
          file-types = ["rs"];
          roots = ["Cargo.toml" "Cargo.lock"];
          shebangs = ["rust-script" "cargo"];
          auto-format = true;
          comment-tokens = ["//" "///" "//!"];
          block-comment-tokens = [
            {
              start = "/*";
              end = "*/";
            }
            {
              start = "/**";
              end = "*/";
            }
            {
              start = "/*!";
              end = "*/";
            }
          ];
          formatter = {
            command = "rustfmt";
          };
          language-servers = ["rust-analyzer"];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
          persistent-diagnostic-sources = ["rustc" "clippy"];
        }

        {
          name = "cpp";
          scope = "source.cpp";
          injection-regex = "cpp";
          file-types = ["cc" "hh" "c++" "cpp" "hpp" "h" "ipp" "cxx" "hxx" "ixx" "txx" "ino" "C" "H" "cu" "cuh" "cppm" "h++" "ii" "inl" {glob = ".hpp.in";} {glob = ".h.in";}];
          comment-token = "//";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          language-servers = ["clangd"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }

        {
          name = "python";
          scope = "source.python";
          injection-regex = "py(thon)?";
          file-types = ["py" "pyi" "py3" "pyw" "ptl" "rpy" "cpy" "ipy" "pyt" {glob = ".python_history";} {glob = ".pythonstartup";} {glob = ".pythonrc";} {glob = "*SConstruct";} {glob = "*SConscript";} {glob = "*sconstruct";}];
          shebangs = ["python" "uv"];
          roots = ["pyproject.toml" "setup.py" "poetry.lock" "pyrightconfig.json"];
          comment-token = "#";
          auto-format = true;
          language-servers = ["pyright" "ruff"];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
        }

        {
          name = "r";
          scope = "source.r";
          injection-regex = "(r|R)";
          file-types = ["r" "R" {glob = ".Rprofile";} {glob = "Rprofile.site";} {glob = ".RHistory";}];
          shebangs = ["r" "R"];
          comment-tokens = ["#" "#'"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          auto-format = true;
          language-servers = ["r-languageserver"];
        }

        {
          name = "rmarkdown";
          scope = "source.rmd";
          language-id = "rmd";
          injection-regex = "(r|R)md";
          file-types = ["rmd" "Rmd"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          grammar = "markdown";
          block-comment-tokens = {
            start = "<!--";
            end = "-->";
          };
          language-servers = ["r-languageserver"];
        }

        {
          name = "nix";
          scope = "source.nix";
          injection-regex = "nix";
          file-types = ["nix"];
          shebangs = [];
          comment-token = "#";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          auto-format = true;
          formatter = {
            command = "alejandra";
            args = ["-"];
          };
          language-servers = ["nil"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }

        {
          name = "markdown";
          scope = "source.md";
          injection-regex = "md|markdown";
          file-types = ["md" "livemd" "markdown" "mdx" "mkd" "mkdn" "mdwn" "mdown"];
          roots = [".marksman.toml"];
          soft-wrap.enable = true;
          soft-wrap.wrap-at-text-width = true;
          soft-wrap.max-wrap = 80;
          language-servers = ["marksman"];
          block-comment-tokens = {
            start = "<!--";
            end = "-->";
          };
          "word-completion.trigger-length" = 4;
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }

        {
          name = "latex";
          scope = "source.tex";
          injection-regex = "tex";
          file-tupes = ["tex" "sty" "cls" "Rd" "bbx" "cbx"];
          comment-token = "%";
          language-servers = ["texlab"];
          indent = {
            tab-width = 4;
            unit = "\t";
          };
        }

        {
          name = "bibtex";
          scope = "source.bib";
          injection-regex = "bib";
          file-tupes = ["bib"];
          comment-token = "%";
          language-servers = ["texlab"];
          indent = {
            tab-width = 4;
            unit = "\t";
          };
          auto-format = true;
          formatter = {
            command = "bibtex-tidy";
            args = ["-" "--curly" "--drop-all-caps" "--remove-empty-fields" "--sort-fields" "--sort=year,author,id" "--strip-enclosing-braces" "--trailing-commas"];
          };
        }

        {
          name = "julia";
          scope = "source.julia";
          injection-regex = "julia";
          file-types = ["jl"];
          shebangs = ["julia"];
          roots = ["Manifest.toml" "Project.toml"];
          comment-token = "#";
          block-comment-tokens = {
            start = "#=";
            end = "=#";
          };
          language-servers = ["julia"];
          indent = {
            tab-width = 4;
            unit = "    ";
          };
        }

        {
          name = "typescript";
          scope = "source.ts";
          injection-regex = "(ts|typescript)";
          language-id = "typescript";
          file-types = ["ts" "mts" "cts"];
          shebangs = ["deno" "bun" "ts-node"];
          roots = ["package.json" "tsconfig.json"];
          comment-token = "//";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          language-servers = ["typescript-language-server"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }

        {
          name = "svelte";
          scope = "source.svelte";
          injection-regex = "svelte";
          file-types = ["svelte"];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          comment-token = "//";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          language-servers = ["svelteserver"];
        }
      ];
    };

    themes = {
      "ashenblack" = let
        palette = {
          cursorline = "#191919";
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
          background = "#000000";
          g_1 = "#e5e5e5";
          g_2 = "#d5d5d5";
          g_3 = "#b4b4b4";
          g_4 = "#a7a7a7";
          g_5 = "#949494";
          g_6 = "#737373";
          g_7 = "#535353";
          g_8 = "#323232";
          g_9 = "#222222";
          g_10 = "#1d1d1d";
          g_11 = "#191919";
          g_12 = "#151515";
        };
      in {
        ## Syntax highlighting
        "attribute" = palette.g_4;
        "type" = palette.blue;
        "type.builtin" = palette.blue;
        "type.parameter" = palette.orange_glow;
        "type.enum.variant" = palette.orange_blaze;
        "constructor" = palette.g_1;
        "constant" = palette.orange_blaze;
        "constant.builtin" = palette.blue;
        "constant.character" = {
          fg = palette.red_glowing;
          modifiers = ["bold"];
        };
        "constant.character.escape" = palette.g_2;
        "constant.numeric" = palette.blue;
        "string" = palette.red_glowing;
        "string.regexp" = palette.orange_glow;
        "string.special" = palette.g_2;
        "string.special.url" = {
          fg = palette.red_glowing;
          modifiers = ["bold"];
        };
        "string.special.path" = {
          fg = palette.red_glowing;
          modifiers = ["bold"];
        };
        "string.special.symbol" = palette.orange_smolder;
        "comment" = {
          fg = palette.g_6;
          modifiers = ["italic"];
        };
        "comment.block.documentation" = {
          fg = palette.g_5;
          modifiers = ["italic"];
        };
        "variable" = palette.g_3;
        "variable.parameter" = {
          fg = palette.g_2;
          modifiers = ["italic"];
        };
        "variable.builtin" = palette.blue;
        "variable.other.member" = {fg = palette.g_2;};
        "label" = palette.red_ember;
        "punctuation" = palette.g_2;
        "punctuation.special" = palette.orange_golden;
        "punctuation.bracket" = palette.g_6;
        "punctuation.delimiter" = palette.orange_smolder;
        "keyword" = palette.red_ember;
        "keyword.operator" = palette.orange_blaze;
        "keyword.directive" = {
          fg = palette.red_ember;
          modifiers = ["italic"];
        };
        "keyword.storage.modifier" = {
          fg = palette.red_ember;
          modifiers = ["italic"];
        };
        "operator" = palette.orange_glow;
        "function" = {
          fg = palette.g_3;
          modifiers = ["bold"];
        };
        "function.builtin" = {
          fg = palette.g_3;
          modifiers = ["bold" "italic"];
        };
        "function.macro" = palette.red_ember;
        "tag" = {
          fg = palette.orange_glow;
          modifiers = ["italic"];
        };
        "namespace" = {
          fg = palette.orange_glow;
          modifiers = ["bold"];
        };
        "special" = palette.orange_smolder;
        "markup.heading" = {
          fg = palette.red_glowing;
          modifiers = ["bold"];
        };
        "markup.list" = palette.orange_glow;
        "markup.bold" = {modifiers = ["bold"];};
        "markup.italic" = {modifiers = ["italic"];};
        "markup.link.url" = {
          fg = palette.red_glowing;
          modifiers = ["italic" "underlined"];
        };
        "markup.link.text" = palette.red_ember;
        "markup.raw" = {
          fg = palette.g_2;
          bg = palette.g_10;
        };
        "markup.quote" = {modifiers = ["italic"];};
        "diff.plus" = palette.g_6;
        "diff.minus" = palette.red_ember;
        "diff.delta" = palette.brown;

        ## User interface
        "ui.background" = {
          fg = palette.text;
          bg = palette.background;
        };
        "ui.linenr" = {fg = palette.g_8;};
        "ui.linenr.selected" = {fg = palette.g_6;};
        "ui.statusline" = {
          fg = palette.g_3;
          bg = palette.g_9;
        };
        "ui.statusline.inactive" = {
          fg = palette.g_5;
          bg = palette.g_10;
        };
        "ui.statusline.normal" = {
          fg = palette.background;
          bg = palette.orange_blaze;
          modifiers = ["bold"];
        };
        "ui.statusline.insert" = {
          fg = palette.g_1;
          bg = palette.g_7;
          modifiers = ["bold"];
        };
        "ui.statusline.select" = {
          fg = palette.background;
          bg = palette.orange_golden;
          modifiers = ["bold"];
        };
        "ui.popup" = {
          fg = palette.text;
          bg = palette.g_10;
        };
        "ui.info" = {
          fg = palette.orange_blaze;
          bg = palette.g_10;
        };
        "ui.window" = {fg = palette.g_7;};
        "ui.help" = {
          fg = palette.text;
          bg = palette.g_10;
          modifiers = ["bold"];
        };
        "ui.bufferline" = {
          fg = palette.text;
          bg = palette.background;
        };
        "ui.bufferline.active" = {
          fg = palette.g_2;
          bg = palette.g_10;
          underline = {
            color = palette.orange_blaze;
            style = "line";
          };
        };
        "ui.bufferline.background" = {bg = palette.background;};
        "ui.text" = palette.text;
        "ui.text.focus" = {
          fg = palette.g_2;
          bg = palette.g_10;
          underline = {
            color = palette.red_ember;
            style = "line";
          };
          modifiers = ["bold"];
        };
        "ui.text.inactive" = {fg = palette.g_7;};
        "ui.text.directory" = {fg = palette.red_ember;};
        "ui.virtual" = palette.g_5;
        "ui.virtual.ruler" = {bg = palette.cursorline;};
        "ui.virtual.whitespace" = palette.g_7;
        "ui.virtual.indent-guide" = palette.g_7;
        "ui.virtual.wrap" = palette.g_7;
        "ui.virtual.inlay-hint" = {
          fg = palette.g_6;
          modifiers = ["italic"];
        };
        "ui.virtual.jump-label" = {
          fg = palette.background;
          bg = palette.orange_blaze;
          modifiers = ["bold"];
        };
        "ui.selection" = {bg = palette.brown_dark;};
        "ui.cursor.normal" = {
          fg = palette.background;
          bg = palette.orange_muted;
        };
        "ui.cursor.insert" = {
          fg = palette.background;
          bg = palette.g_7;
        };
        "ui.cursor.select" = {
          fg = palette.background;
          bg = palette.golden_muted;
        };
        "ui.cursor.primary.normal" = {
          fg = palette.background;
          bg = palette.orange_blaze;
          modifiers = ["bold"];
        };
        "ui.cursor.primary.insert" = {
          fg = palette.background;
          bg = palette.g_3;
          modifiers = ["bold"];
        };
        "ui.cursor.primary.select" = {
          fg = palette.background;
          bg = palette.orange_golden;
          modifiers = ["bold"];
        };
        "ui.cursor.match" = {
          fg = palette.orange_smolder;
          modifiers = ["underlined"];
        };
        "ui.cursorline.primary" = {bg = palette.cursorline;};
        "ui.cursorline" = {bg = palette.g_12;};
        "ui.highlight" = {
          fg = palette.orange_blaze;
          bg = palette.cursorline;
          underline = {
            color = palette.red_ember;
            style = "line";
          };
          modifiers = ["bold"];
        };
        "ui.menu" = {
          fg = palette.g_2;
          bg = palette.g_10;
        };
        "ui.menu.selected" = {
          fg = palette.background;
          bg = palette.orange_blaze;
          modifiers = ["bold"];
        };

        ## Diagnostics & misc
        error = {
          fg = palette.red_flame;
          bg = palette.g_10;
        };
        warning = {
          fg = palette.orange_golden;
          bg = palette.g_10;
        };
        info = {
          fg = palette.g_2;
          bg = palette.g_10;
        };
        hint = {
          fg = palette.g_4;
          bg = palette.g_10;
        };
        "diagnostic.error" = {
          underline = {
            color = palette.red_flame;
            style = "curl";
          };
        };
        "diagnostic.warning" = {
          underline = {
            color = palette.orange_golden;
            style = "curl";
          };
        };
        "diagnostic.info" = {
          underline = {
            color = palette.g_4;
            style = "dotted";
          };
        };
        "diagnostic.hint" = {
          underline = {
            color = palette.g_5;
            style = "dotted";
          };
        };
        "diagnostic.unnecessary" = {modifiers = ["dim"];};
      };
    };
  };

  home.packages = with pkgs; [
    nil
    rust-analyzer
    rustfmt
    pyright
    typescript-language-server
    svelte-language-server
    bash-language-server
    R
    tree-sitter
    clang-tools
    julia
    idris2Packages.idris2Lsp
    ruff
    marksman
    texlab
    tailwindcss-language-server
  ];
}
