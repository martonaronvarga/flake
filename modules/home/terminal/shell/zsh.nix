{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    nix-zsh-completions
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    autocd = true;
    dotDir = config.xdg.configHome + "/zsh";

    history = {
      ignorePatterns = ["rm *" "pkill *"];
      append = true;
      expireDuplicatesFirst = true;
      path = "${config.xdg.dataHome}/.zsh_history";
    };

    envExtra = ''
      BAT_THEME=base16
      FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      FZF_CTRL_T_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
      FZF_DEFAULT_OPTS="
        --height ~100%
        --tmux 100%,100%
        --layout=reverse
        --border
        --info=inline
        --prompt=
        --scrollbar=
        --separator=
        --pointer='>'
        --marker='*'
        --preview-window=right:50%:border-left
        --color=border:#1a1a1a
        --color=bg:#000000
        --color=bg+:#1a1a1a
        --color=fg:#d0d0d0
        --color=fg+:#ffffff
        --color=hl:#33aa77
        --color=hl+:#33aa77
        --color=info:#aaaaaa
        --color=prompt:#e25303
        --color=pointer:#e25303
        --color=marker:#33aa77
        --color=spinner:#e25303
        --color=header:#5e676e
        --bind "ctrl-y:execute-silent(printf {} | cut -f 2- | wl-copy --trim-newline)"
      "
      FZF_CTRL_T_OPTS="
        --ansi --preview 'bat -n --color=always --style=numbers --line-range :300 {}'
        --walker-skip .git,node_modules,target
        --bind 'ctrl-/:change-preview-window(down|hidden|)'
      "
      FZF_CTRL_R_OPTS="
        --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
        --color header:italic
        --header 'Press CTRL-Y to copy command into clipboard'
      "

      FZF_ALT_C_OPTS="
        --ansi --preview 'eza --tree --color=always --icons {} | head -200'
        --walker-skip .git,node_modules,target
      "

      FZF_COMPLETION_PATH_OPTS="--walker file,dir,follow,hidden"
      FZF_COMPLETION_DIR_OPTS="--walker dir,follow"

    '';

    shellAliases = {
      eltehpc = "kitty +kitten ssh atlasz";
      eltevpn = "nmcli connection up elte-vpn";
      eltevpnstop = "nmcli connection down elte-vpn";
      ssh = "kitty +kitten ssh";
      xopen = "xdg-open";
      c = "clear";
      q = "exit";
      cleanram = "sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches";
      trim_all = "sudo fstrim -av";
      mtar = "tar -zcvf"; # mtar <archive_compress>
      utar = "tar -zxvf"; # utar <archive_decompress> <file_list>
      zip = "zip -r"; # zip <archive_name> <file_list>
      ".." = "cd ..";
      cd = "z";
      mkdir = "mkdir -p";
      fm = "yazi";
      ls = "eza --color=auto --icons --git";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      cat = "bat --color=auto --plain --paging=never";
      batp = "bat --color=always --plain --paging=never";
      grep = "grep --color=auto";
      mv = "mv -v";
      cp = "cp -vr";
      gst = "git status";
      ga = "git add";
      gcmsg = "git commit -m";
      ip = "ip --color";
    };

    shellGlobalAliases = {
      UUID = "$(uuidgen | tr -d \\n)";
      G = "| grep";
      J = "| jq";
      C = "| wl-copy";
    };

    siteFunctions = {
      mkcd = ''
        mkdir --parents "$1" && cd "$1"
      '';
      d = ''
        dirs -v
      '';
      rm = ''
        command rm -Iv "$@"
      '';
      extract = ''
        case "$1" in
           *.tar.bz2) tar xjf "$1" ;;
           *.tar.gz)  tar xzf "$1" ;;
           *.tar.xz)  tar xJf "$1" ;;
           *.zip)     unzip "$1" ;;
           *) echo "unknown archive format" ;;
         esac
      '';

      f = ''
        local program="$1"
        shift || return 1

        local -a files
        files=("''${(@f)$(fzf --multi)}")
        (( ''${#files} )) || return 1

        print -s -- "$program ''${(q)@} ''${(q)files}"
        case "$program" in
          zathura|vlc) command "$program" "$@" "''${files[@]}" & ;;
          *) command "$program" "$@" "''${files[@]}" ;;
        esac
      '';
      ff = ''
        local program="$1"
        shift || return 1

        local -a files
        files=("''${(@f)$(fd --type f --max-depth 1 | fzf --multi)}")
        (( ''${#files} )) || return 1

        print -s -- "$program ''${(q)@} ''${(q)files}"
        case "$program" in
          zathura|vlc) command "$program" "$@" "''${files[@]}" & ;;
          *) command "$program" "$@" "''${files[@]}" ;;
        esac
      '';
      cf = ''
        local file
        file="$(fd --hidden --follow --exclude .git . | fzf --select-1 --exit-0)"
        [[ -z "$file" ]] && return 1

        if [[ -d "$file" ]]; then
          cd -- "$file"
        else
          cd -- "''${file:h}"
        fi
      '';
      fe = ''
        local -a files
        files=("''${(@f)$(fzf-tmux --query="$1" --multi --select-1 --exit-0 --preview="bat --color=always {}")}")
        (( ''${#files} )) && ''${EDITOR:-hx} "''${files[@]}"
      '';
      frg = ''
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for\!"; return 1; fi
        rg --line-number --no-heading --color=always --smart-case "''${*:-}" |
        fzf --ansi --delimiter : \
          --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
          --bind 'enter:become(''${EDITOR:-hx} {1} +{2})'
      '';
      fkill = ''
        local pid
        if [ "$UID" != "0" ]; then
          pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
        else
          pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
        fi

        if [ "x$pid" != "x" ]
        then
          echo $pid | xargs kill -''${1:-9}
        fi

      '';
      tm = ''
        [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
        if [[ -n "$1" ]]; then
          tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux $change -t "$1")
          return
        fi
        session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && tmux $change -t "$session" || echo "No sessions found."
      '';
      eltevpn-setup = ''
        nmcli connection show elte-vpn >/dev/null 2>&1 || \
          nmcli connection add type vpn vpn-type fortisslvpn con-name elte-vpn ifname "*" user usumusu -- \
            vpn.data "gateway=fw1.vpn.elte.hu:4443"
        local uuid
        uuid="$(nmcli --get-values connection.uuid connection show elte-vpn)" || return
        nm-connection-editor --edit "$uuid" >/dev/null 2>&1 &!
      '';
      gco = ''
        git checkout "$(git branch --all | sed 's/^[* ] //' | fzf \
        --preview 'git log -n 20 --color=always {}')"
      '';
      grb = ''
        git rebase -i "$(git log --oneline | fzf | awk '{print $1}')"
      '';
      gedit = ''
        git diff --name-only | fzf -m \
          --preview 'bat --color=always {}' \
          | xargs -r ''${EDITOR:-hx}
      '';
      gstash = ''
        git stash apply "$(git stash list | fzf | cut -d: -f1)"
      '';
    };
    setOptions = [
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "NOMATCH"
      "EXTENDED_HISTORY"
    ];

    initContent = ''
      bindkey "''${key[Up]}" up-line-or-search

      if [[ $(tty) == /dev/tty1 ]]; then
        if uwsm check may-start; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      fi
    '';
  };
  programs.bat.enable = true;
}
