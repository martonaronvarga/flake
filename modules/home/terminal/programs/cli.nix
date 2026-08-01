{
  config,
  pkgs,
  ...
}: let
  fzf = pkgs.symlinkJoin {
    name = "fzf-with-colors";
    inherit (pkgs.fzf) version;
    paths = [pkgs.fzf];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/fzf" \
        --unset NO_COLOR \
        --add-flags "--color=bg:black,bg+:bright-black,fg:white,fg+:bright-white,hl:white,hl+:bright-white,border:bright-black,label:white,info:white,header:white,prompt:white,pointer:white,marker:white,spinner:white,query:bright-white,gutter:black"
    '';
    meta.mainProgram = "fzf";
  };

  repoPublish = pkgs.writeShellApplication {
    name = "repo-publish";
    runtimeInputs = with pkgs; [
      coreutils
      git
      radicle-node
    ];
    text = ''
      repository="''${1:-.}"
      root=$(git -C "$repository" rev-parse --show-toplevel)
      branch=$(git -C "$root" symbolic-ref --quiet --short HEAD) || {
        echo "repo-publish: detached HEAD is not publishable" >&2
        exit 1
      }

      origin_url=$(git -C "$root" remote get-url origin)
      case "$origin_url" in
        *git.martonaronvarga.dev/usu/* | forgejo:usu/* | ssh://forgejo/usu/*) ;;
        *)
          echo "repo-publish: origin is not the canonical Forgejo remote: $origin_url" >&2
          exit 1
          ;;
      esac

      if ! git -C "$root" diff --quiet ||
        ! git -C "$root" diff --cached --quiet ||
        test -n "$(git -C "$root" ls-files --others --exclude-standard)"; then
        echo "repo-publish: warning: the working tree is dirty; only committed work will be published" >&2
      fi

      head=$(git -C "$root" rev-parse HEAD)
      echo "repo-publish: pushing $branch to Forgejo"
      git -C "$root" push origin "HEAD:refs/heads/$branch" --follow-tags
      forgejo_head=$(git -C "$root" ls-remote origin "refs/heads/$branch" | cut -f1)
      if test "$forgejo_head" != "$head"; then
        echo "repo-publish: Forgejo verification failed ($forgejo_head != $head)" >&2
        exit 1
      fi
      echo "repo-publish: Forgejo verified at $head"

      if rid=$(rad inspect --rid "$root" 2>/dev/null); then
        if test -z "''${SSH_AUTH_SOCK:-}"; then
          SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/gcr/ssh"
          export SSH_AUTH_SOCK
        fi
        if test ! -S "$SSH_AUTH_SOCK"; then
          echo "repo-publish: SSH agent socket is unavailable: $SSH_AUTH_SOCK" >&2
          exit 1
        fi
        if test -r /run/agenix/radicle-user-passphrase; then
          RAD_PASSPHRASE="$(< /run/agenix/radicle-user-passphrase)" \
            rad auth
        fi
        echo "repo-publish: pushing $branch to $rid"
        git -C "$root" push rad "HEAD:refs/heads/$branch"
        radicle_home=$(rad self --home)
        node_id=$(rad node status --only nid)
        radicle_head=$(
          git \
            --git-dir="$radicle_home/storage/''${rid#rad:}" \
            rev-parse "refs/namespaces/$node_id/refs/heads/$branch"
        )
        if test "$radicle_head" != "$head"; then
          echo "repo-publish: Radicle verification failed ($radicle_head != $head)" >&2
          exit 1
        fi
        echo "repo-publish: syncing $rid with the dusk seed"
        (
          cd "$root"
          rad sync \
            --seed z6MknCPa2uX2xtrRHHj5e9joMAmAnukNznzTgqSLLbJ1uHtv \
            --replicas 1 \
            --timeout 30s
          rad sync status
        )
      else
        echo "repo-publish: no Radicle identity; skipping Radicle"
      fi

      if git -C "$root" remote get-url github >/dev/null 2>&1; then
        echo "repo-publish: waiting for the Forgejo push mirror"
        github_head=""
        for _ in $(seq 1 12); do
          github_head=$(git -C "$root" ls-remote github "refs/heads/$branch" | cut -f1)
          test "$github_head" = "$head" && break
          sleep 10
        done
        if test "$github_head" != "$head"; then
          echo "repo-publish: GitHub mirror did not reach $head within 2 minutes" >&2
          exit 1
        fi
        echo "repo-publish: GitHub mirror verified at $head"
      else
        echo "repo-publish: no GitHub remote; skipping mirror verification"
      fi
    '';
  };

  shellNavigation = with pkgs; [
    eza
    fd
    ripgrep
    tree
    zoxide
  ];

  fileInspection = with pkgs; [
    bat
    exiftool
    file
  ];

  archivesAndTransfer = with pkgs; [
    croc
    rsync
    unzip
    zip
  ];

  monitoring = with pkgs; [
    btop
    gping
  ];

  terminalFun = with pkgs; [
    figlet
    lolcat
    fastfetch
  ];

  defaultBuildTools = with pkgs; [
    cargo
    gcc
    gnumake
    pkg-config
    shfmt
  ];

  generalUtilities = with pkgs; [
    jq
    libgcc
    tldr
    tmux
  ];
in {
  # Keep the former options-file path valid for shells that were started before
  # FZF_DEFAULT_OPTS_FILE was removed from the session environment.  The file is
  # derived from Home Manager's fzf options, so it cannot drift independently.
  xdg.configFile."fzf/fzfrc".text = config.home.sessionVariables.FZF_DEFAULT_OPTS;

  home.packages =
    [repoPublish]
    ++ shellNavigation
    ++ fileInspection
    ++ archivesAndTransfer
    ++ monitoring
    ++ terminalFun
    ++ defaultBuildTools
    ++ generalUtilities;

  programs = {
    eza.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
      package = fzf;
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
      fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
      defaultOptions = [
        "--height=80%"
        "--layout=reverse"
        "--cycle"
        "--border"
        "--info=inline"
        "--prompt=>"
        "--scrollbar=|"
        "--separator=-"
        "--no-bold"
        "--pointer=>"
        "--marker=*"
        "--color=bg:black,bg+:bright-black,fg:white,fg+:bright-white,hl:white,hl+:bright-white,border:bright-black,label:white,info:white,header:white,prompt:white,pointer:white,marker:white,spinner:white,query:bright-white,gutter:black"
        "--preview-window=right:50%:border-left"
        "--bind='ctrl-y:execute-silent(printf {} | cut -f 2- | wl-copy --trim-newline)'"
        "--bind=ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up"
        "--bind=tab:down,btab:up"
      ];
      fileWidgetOptions = [
        "--preview='bat -n --color=never --style=numbers --line-range :300 {}'"
        "--preview-window=right:50%:border-left"
        "--walker-skip=.git,node_modules,target"
        "--bind='ctrl-/:change-preview-window(down|hidden|)'"
      ];
      historyWidgetOptions = [
        "--height=60%"
        "--layout=reverse"
        "--border=rounded"
        "--info=inline"
        "--prompt=history>"
        "--pointer=>"
        "--marker=*"
        "--no-multi"
        "--no-wrap"
        "--bind=ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up"
        "--bind=tab:down,btab:up"
        "--bind='ctrl-y:execute-silent(printf %s {2..} | wl-copy --trim-newline)+abort'"
        "--color=header:italic"
        "--header='enter: insert  ctrl-y: copy  ctrl-r: sort  esc: cancel'"
      ];
      changeDirWidgetOptions = [
        "--preview='eza --tree --color=never --icons {} | head -200'"
        "--walker-skip=.git,node_modules,target"
        "--preview-window=right:50%:border-left"
      ];
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
