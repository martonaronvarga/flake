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
      export BAT_THEME=base16
      export OCI_CLI_CONFIG_FILE="$HOME/.config/oci/config"
      export OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING=True
      export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

      export FZF_DEFAULT_OPTS='
        --height=80%
        --layout=reverse
        --cycle
        --border
        --info=inline
        --prompt=>\
        --scrollbar=|
        --separator=-
        --no-bold
        --pointer=>
        --marker=*
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
        --bind=ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up
        --bind=tab:down,btab:up
      '

      export FZF_CTRL_T_OPTS='
        --ansi
        --preview "bat -n --color=always --style=numbers --line-range :300 {}"
        --preview-window=right:50%:border-left
        --walker-skip .git,node_modules,target
        --bind "ctrl-/:change-preview-window(down|hidden|)"
      '

      export FZF_CTRL_R_OPTS='
        --height=60%
        --layout=reverse
        --border=rounded
        --info=inline
        --prompt=history>\
        --pointer=>
        --marker=*
        --no-multi
        --no-wrap
        --bind=ctrl-j:down,ctrl-k:up,ctrl-n:down,ctrl-p:up
        --bind=tab:down,btab:up
        --bind "ctrl-y:execute-silent(printf %s {2..} | wl-copy --trim-newline)+abort"
        --color header:italic
        --header "enter: insert  ctrl-y: copy  ctrl-r: sort  esc: cancel"
      '

      export FZF_ALT_C_OPTS='
        --ansi
        --preview "eza --tree --color=always --icons {} | head -200"
        --walker-skip .git,node_modules,target
        --preview-window=right:50%:border-left
      '

      export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'
      export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'
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
        (( $# == 1 )) || {
          print -u2 -- "usage: extract ARCHIVE"
          return 2
        }
        case "$1" in
           *.tar.bz2) tar xjf "$1" ;;
           *.tar.gz)  tar xzf "$1" ;;
           *.tar.xz)  tar xJf "$1" ;;
           *.zip)     unzip "$1" ;;
           *) echo "unknown archive format" ;;
         esac
      '';

      f = ''
        (( $# >= 1 )) || {
          print -u2 -- "usage: f PROGRAM [PROGRAM_ARGUMENT ...]"
          return 2
        }

        local program="$1"
        shift
        (( $+commands[$program] )) || {
          print -u2 -- "f: command not found: $program"
          return 127
        }

        local -a files
        files=("''${(@f)$(fzf --multi --header='enter: open  tab: select  esc: cancel')}")
        (( ''${#files} )) || return 0

        print -s -- "$program ''${(q)@} ''${(q)files}"
        case "$program" in
          zathura|vlc) command "$program" "$@" "''${files[@]}" & ;;
          *) command "$program" "$@" "''${files[@]}" ;;
        esac
      '';
      ff = ''
        (( $# >= 1 )) || {
          print -u2 -- "usage: ff PROGRAM [PROGRAM_ARGUMENT ...]"
          return 2
        }

        local program="$1"
        shift
        (( $+commands[$program] )) || {
          print -u2 -- "ff: command not found: $program"
          return 127
        }

        local -a files
        files=("''${(@f)$(fd --type f --max-depth 1 --strip-cwd-prefix | fzf --multi --header='enter: open  tab: select  esc: cancel')}")
        (( ''${#files} )) || return 0

        print -s -- "$program ''${(q)@} ''${(q)files}"
        case "$program" in
          zathura|vlc) command "$program" "$@" "''${files[@]}" & ;;
          *) command "$program" "$@" "''${files[@]}" ;;
        esac
      '';
      cf = ''
        local file
        file="$(fd --hidden --follow --exclude .git --strip-cwd-prefix . | fzf \
          --select-1 --exit-0 \
          --header='enter: cd to directory or containing directory  esc: cancel')"
        [[ -z "$file" ]] && return 0

        if [[ -d "$file" ]]; then
          cd -- "$file"
        else
          cd -- "''${file:h}"
        fi
      '';
      fe = ''
        local -a files
        files=("''${(@f)$(fzf --query="''${1:-}" --multi --select-1 --exit-0 \
          --preview='bat --color=always --style=numbers --line-range=:300 -- {}' \
          --header='enter: edit  tab: select  esc: cancel')}")
        (( ''${#files} )) || return 0
        ''${EDITOR:-hx} "''${files[@]}"
      '';
      frg = ''
        (( $# >= 1 )) || {
          print -u2 -- "usage: frg SEARCH_PATTERN"
          return 2
        }

        rg --line-number --no-heading --color=always --smart-case "''${*:-}" |
        fzf --ansi --delimiter : \
          --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
          --header='enter: edit match  esc: cancel' \
          --bind 'enter:become(''${EDITOR:-hx} {1}:{2})'
      '';
      fkill = ''
        local signal="''${1:-TERM}"
        local -a pids

        kill -l "$signal" >/dev/null 2>&1 || {
          print -u2 -- "usage: fkill [SIGNAL]"
          return 2
        }

        pids=("''${(@f)$(ps -o pid=,user=,stat=,etime=,command= -u "$UID" |
          fzf --multi \
            --header="enter: send SIG$signal  tab: select  esc: cancel" |
          awk '{print $1}')}")
        (( ''${#pids} )) || return 0
        kill -s "$signal" -- "''${pids[@]}"
      '';
      tm = ''
        local change session
        [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
        if [[ -n "$1" ]]; then
          tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux $change -t "$1")
          return
        fi
        session="$(tmux list-sessions -F "#{session_name}" 2>/dev/null |
          fzf --exit-0 --header='enter: attach  esc: cancel')" || return 0
        [[ -n "$session" ]] || {
          print -u2 -- "tm: no sessions found (pass a name to create one)"
          return 0
        }
        tmux "$change" -t "$session"
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
        git rev-parse --git-dir >/dev/null 2>&1 || {
          print -u2 -- "gco: not inside a Git repository"
          return 2
        }

        local branch
        branch="$(git branch --all --format='%(refname:short)' |
          fzf --header='enter: checkout branch  esc: cancel' \
            --preview 'git log -n 20 --color=always -- {}')"
        [[ -n "$branch" ]] || return 0
        git checkout -- "$branch"
      '';
      grb = ''
        git rev-parse --git-dir >/dev/null 2>&1 || {
          print -u2 -- "grb: not inside a Git repository"
          return 2
        }

        local commit
        commit="$(git log --oneline --decorate |
          fzf --header='enter: rebase commits after selection  esc: cancel' |
          awk '{print $1}')"
        [[ -n "$commit" ]] || return 0
        git rebase -i "$commit"
      '';
      gedit = ''
        git rev-parse --git-dir >/dev/null 2>&1 || {
          print -u2 -- "gedit: not inside a Git repository"
          return 2
        }

        local -a files
        files=("''${(@f)$({
          git diff --name-only
          git diff --cached --name-only
          git ls-files --others --exclude-standard
        } | sort -u | fzf --multi \
          --preview 'bat --color=always --style=numbers -- {}' \
          --header='enter: edit  tab: select  esc: cancel')}")
        (( ''${#files} )) || return 0
        ''${EDITOR:-hx} "''${files[@]}"
      '';
      gstash = ''
        git rev-parse --git-dir >/dev/null 2>&1 || {
          print -u2 -- "gstash: not inside a Git repository"
          return 2
        }

        local stash
        stash="$(git stash list |
          fzf --header='enter: apply stash  esc: cancel' |
          cut -d: -f1)"
        [[ -n "$stash" ]] || return 0
        git stash apply "$stash"
      '';
      fzf-help = ''
        print -r -- 'fzf key bindings'
        printf '  %-24s %s\n' \
          'Ctrl-R' 'search shell history; one command per row' \
          'Ctrl-T' 'insert selected file paths into the command line' \
          'Alt-C' 'change to a selected directory' \
          'COMMAND **<Tab>' 'fuzzy-complete paths, PIDs, hosts, and similar values'

        print -r -- $'\nCommon selector keys'
        printf '  %-24s %s\n' \
          'type' 'filter the candidates' \
          'Enter' 'accept the current candidate' \
          'Esc' 'cancel without changing anything' \
          'Ctrl-J/K or Ctrl-N/P' 'move down/up' \
          'Tab / Shift-Tab' 'select or move when multi-select is enabled' \
          'Ctrl-Y' 'copy the current history command'

        print -r -- $'\nfzf helper functions'
        printf '  %-24s %s\n' \
          'f PROGRAM [ARGS...]' 'recursively select files and open them with PROGRAM' \
          'ff PROGRAM [ARGS...]' 'select files from only the current directory' \
          'cf' 'enter a selected directory or the parent of a selected file' \
          'fe [QUERY]' 'select files recursively and open them in $EDITOR' \
          'frg PATTERN' 'search file contents and edit a selected match' \
          'fkill [SIGNAL]' 'select your processes and signal them; default TERM' \
          'tm [SESSION]' 'select, attach to, or create a tmux session' \
          'gco' 'select and check out a Git branch' \
          'grb' 'select the base commit for an interactive rebase' \
          'gedit' 'edit selected changed or untracked Git files' \
          'gstash' 'select and apply a Git stash'

        print -r -- $'\nCompletion examples'
        printf '  %s\n' \
          'cat **<Tab>    cd **<Tab>    kill **<Tab>    ssh **<Tab>'

        print -r -- $'\nRun `fzf --man` for the full reference.'
        print -r -- 'See docs/fzf-cheatsheet.md in the flake for examples and cautions.'
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

      # fzf 0.74 intentionally displays multiline history entries across
      # multiple screen rows. Present a flattened preview instead, then restore
      # the original command (including its newlines) into the editing buffer.
      fzf-history-widget() {
        emulate -L zsh
        setopt localoptions pipefail no_aliases

        local id command display selected
        selected="$({
          for id in ''${(Onk)history}; do
            command="''${history[$id]}"
            display="''${command//$'\n'/ ↵ }"
            display="''${display//$'\t'/  }"
            printf '%s\t%s\0' "$id" "$display"
          done
        } | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_R_OPTS" \
          FZF_DEFAULT_OPTS_FILE= fzf \
          --read0 \
          --delimiter=$'\t' \
          --with-nth=2.. \
          --nth=2.. \
          --scheme=history \
          --query="$LBUFFER" \
          --bind=ctrl-r:toggle-sort)" || {
            zle reset-prompt
            return 0
          }

        id="''${selected%%$'\t'*}"
        if [[ "$id" == <-> && -n "''${history[$id]-}" ]]; then
          BUFFER="''${history[$id]}"
          CURSOR=''${#BUFFER}
        fi
        zle reset-prompt
      }
      zle -N fzf-history-widget
      bindkey '^R' fzf-history-widget

      if [[ $(tty) == /dev/tty1 ]]; then
        if uwsm check may-start; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      fi
    '';
  };
  programs.bat.enable = true;
}
