{config, ...}: {
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 80;
      scan_timeout = 20;

      username = {
        style_user = "bright-white bold";
        style_root = "bright-red bold";
        format = "[$username]($style)";
        show_always = true;
      };
      character = {
        success_symbol = "[](bold white)";
        error_symbol = "[](bold red)";
      };

      git_status = {
        untracked = "";
        conflicted = "";
        ahead = "";
        behind = "";
        diverged = "";
        deleted = "✗";
        modified = "✶";
        staged = "✓";
        stashed = "≡";
      };

      nix_shell = {
        symbol = "  ";
        format = "[$symbol$name]($style)";
        heuristic = false;
      };

      shlvl = {
        disabled = false;
        format = "$shlvl ▼ ";
        style = "bright bold yellow";
        threshold = 4;
      };
      # Nerdfonts
      aws = {symbol = "  ";};
      buf = {symbol = " ";};
      c = {symbol = " ";};
      conda = {symbol = " ";};
      dart = {symbol = " ";};
      directory = {read_only = " ";};
      docker_context = {symbol = " ";};
      elixir = {symbol = " ";};
      elm = {symbol = " ";};
      fossil_branch = {symbol = " ";};
      git_branch = {symbol = " ";};
      golang = {symbol = " ";};
      guix_shell = {symbol = " ";};
      haskell = {symbol = " ";};
      haxe = {symbol = "⌘ ";};
      hg_branch = {symbol = " ";};
      hostname = {ssh_symbol = " ";};
      java = {symbol = " ";};
      julia = {symbol = " ";};
      lua = {symbol = " ";};
      memory_usage = {symbol = " ";};
      meson = {symbol = "喝 ";};
      nim = {symbol = " ";};
      nodejs = {symbol = " ";};
      os = {
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = " ";
          Gentoo = " ";
          HardenedBSD = "ﲊ ";
          Illumos = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = " ";
          openSUSE = " ";
          OracleLinux = " ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          Redox = " ";
          Solus = "ﴱ ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = " ";
        };
      };
      package = {symbol = " ";};
      pijul_channel = {symbol = "🪺 ";};
      python = {symbol = " ";};
      rlang = {symbol = " ";};
      ruby = {symbol = " ";};
      rust = {symbol = " ";};
      scala = {symbol = " ";};
      spack = {symbol = " ";};
    };
  };
}
