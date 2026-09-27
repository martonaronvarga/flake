{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) domain mail;
  gitName = "Marton A. Varga";
  gitEmail = "git@${domain}";
  gmailEmail = mail.sender;
  domainEmailAliases = mail.aliases;
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3xygPFeJRmLkyiV0P/vak54Wh7ggq9B6HanmUa137A usu@shade";
  githubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAY1cx1Encvc+3ovWpbyM0H1W7uIsXPanAXLlWoyvm/9 git@github.com";
  gitCredentialForgejoPass = pkgs.writeShellApplication {
    name = "git-credential-forgejo-pass";
    runtimeInputs = [
      pkgs.pass
    ];
    text = ''
      set -euo pipefail

      action="''${1:-get}"
      if [ "$action" != "get" ]; then
        exit 0
      fi

      protocol=""
      host=""
      username=""

      while IFS= read -r line; do
        [ -n "$line" ] || break
        key="''${line%%=*}"
        value="''${line#*=}"
        case "$key" in
          protocol) protocol="$value" ;;
          host) host="$value" ;;
          username) username="$value" ;;
        esac
      done

      [ "$protocol" = "https" ] || exit 0
      [ "$host" = "git.${domain}" ] || exit 0
      [ -z "$username" ] || [ "$username" = "usu" ] || exit 0

      if tty_path="$(tty 2>/dev/null)" && [ "$tty_path" != "not a tty" ]; then
        export GPG_TTY="$tty_path"
        gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
      fi

      token="$(pass show git/git.${domain}/usu)"
      printf 'username=usu\n'
      printf 'password=%s\n' "$token"
    '';
  };
in {
  home.packages = [
    pkgs.gh
    pkgs.pass
  ];

  # enable scrolling in git diff
  home.sessionVariables.DELTA_PAGER = "less -R";

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      user = {
        name = gitName;
        email = gitEmail;
      };

      apply.whitespace = "warn";
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      core.whitespace = "blank-at-eol,blank-at-eof,space-before-tab";
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        renames = "copies";
        wsErrorHighlight = "all";
      };
      fetch = {
        prune = true;
        pruneTags = true;
      };
      init.defaultBranch = "main";
      log = {
        date = "iso";
        decorate = "short";
      };
      merge.conflictstyle = "diff3";
      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };
      pull.rebase = true;
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      rerere = {
        autoupdate = true;
        enabled = true;
      };
      status = {
        branch = true;
        showStash = true;
      };
      tag.sort = "version:refname";
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      };
      sendemail = {
        # home manager pulls in msmtp config for this, so identity is enough
        identity = "personal";
        confirm = "auto";
      };

      "credential \"https://github.com\"" = {
        helper = "!${lib.getExe pkgs.gh} auth git-credential";
        username = "martonaronvarga";
      };
      "credential \"https://git.${domain}\"" = {
        helper = "${lib.getExe gitCredentialForgejoPass}";
        username = "usu";
      };
      "url \"git@github.com:martonaronvarga/\"" = {
        insteadOf = [
          "gh:martonaronvarga/"
          "github:martonaronvarga/"
        ];
      };
      "url \"https://github.com/martonaronvarga/\"" = {
        insteadOf = [
          "gh-https:martonaronvarga/"
          "github-https:martonaronvarga/"
        ];
      };
      "url \"ssh://forgejo/\"" = {
        insteadOf = [
          "forge:"
          "forgejo:"
        ];
      };
      "url \"https://git.${domain}/\"" = {
        insteadOf = [
          "forge-https:"
          "forgejo-https:"
        ];
      };

      alias = let
        log = "log --show-notes='*' --abbrev-commit --pretty=format:'%Cred%h %Cgreen(%aD)%Creset -%C(bold red)%d%Creset %s %C(bold blue)<%an>% %Creset' --graph";
      in {
        a = "add --patch"; # make it a habit to consciously add hunks
        ad = "add";

        b = "branch";
        ba = "branch -a"; # list remote branches
        bd = "branch --delete";
        bdd = "branch -D";

        c = "commit";
        ca = "commit --amend";
        cm = "commit --message";

        co = "checkout";
        cb = "checkout -b";
        pc = "checkout --patch";

        cl = "clone";

        d = "diff";
        ds = "diff --staged";

        h = "show";
        h1 = "show HEAD^";
        h2 = "show HEAD^^";
        h3 = "show HEAD^^^";
        h4 = "show HEAD^^^^";
        h5 = "show HEAD^^^^^";

        p = "push";
        pf = "push --force-with-lease --force-if-includes";

        pl = "pull";

        l = log;
        lp = "${log} --patch";
        la = "${log} --all";

        r = "rebase";
        ra = "rebase --abort";
        rc = "rebase --continue";
        ri = "rebase --interactive";

        rs = "reset";
        rsh = "reset --hard";

        s = "status --short --branch";
        ss = "status";

        st = "stash";
        stc = "stash clear";
        sth = "stash show --patch";
        stl = "stash list";
        stp = "stash pop";

        forgor = "commit --amend --no-edit";
        oops = "checkout --";
      };
    };

    ignores = ["*~" "*.swp" "*result*" ".direnv" "node_modules"];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
    };
  };

  xdg.configFile."git/allowed_signers".text =
    lib.concatMapStringsSep "\n" (email: "${email} namespaces=\"git\" ${signingKey}") (domainEmailAliases ++ [gmailEmail])
    + ''

      ${gmailEmail} namespaces="git" ${githubKey}
    '';
}
