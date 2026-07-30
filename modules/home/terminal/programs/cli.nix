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
    shellNavigation
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
