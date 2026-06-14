{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.git;
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAY1cx1Encvc+3ovWpbyM0H1W7uIsXPanAXLlWoyvm/9 git@github.com";
in {
  home.packages = [pkgs.gh];

  # enable scrolling in git diff
  home.sessionVariables.DELTA_PAGER = "less -R";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Marton A. Varga";
        email = "martonaronvarga@gmail.com";
      };

      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";
      pull.rebase = true;
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
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
        pf = "push --force-with-lease";

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

  xdg.configFile."git/allowed_signers".text = ''
    ${cfg.settings.user.email} namespaces="git" ${key}
  '';
}
