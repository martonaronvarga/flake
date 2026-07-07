{
  config,
  lib,
  pkgs,
  ...
}: let
  gitName = "Marton A. Varga";
  gitEmail = "martonaronvarga@gmail.com";
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAY1cx1Encvc+3ovWpbyM0H1W7uIsXPanAXLlWoyvm/9 git@github.com";
  gitCredentialAercOauth = pkgs.writers.writePython3Bin "git-credential-aerc-oauth" {} ''
    import json
    import sys
    import urllib.parse
    import urllib.request
    from pathlib import Path

    USERNAME = "${gitEmail}"
    TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"
    CLIENT_ID_PATH = Path("/run/agenix/aerc-client-id")
    CLIENT_SECRET_PATH = Path("/run/agenix/aerc-client-secret")
    REFRESH_TOKEN_PATH = Path("/run/agenix/aerc-refresh-token")


    def parse_credential():
        credential = {}
        for line in sys.stdin:
            line = line.rstrip("\n")
            if not line:
                break
            key, _, value = line.partition("=")
            credential[key] = value
        return credential


    def read_secret(path):
        return path.read_text().strip()


    def access_token():
        data = urllib.parse.urlencode(
            {
                "client_id": read_secret(CLIENT_ID_PATH),
                "client_secret": read_secret(CLIENT_SECRET_PATH),
                "refresh_token": read_secret(REFRESH_TOKEN_PATH),
                "grant_type": "refresh_token",
            }
        ).encode()
        request = urllib.request.Request(
            TOKEN_ENDPOINT,
            data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=20) as response:
            payload = json.loads(response.read().decode())
        return payload["access_token"]


    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action != "get":
        sys.exit(0)

    credential = parse_credential()
    if credential.get("host") != "smtp.gmail.com":
        sys.exit(0)
    if credential.get("username", USERNAME) != USERNAME:
        sys.exit(0)

    try:
        token = access_token()
    except Exception as error:
        print(f"git-credential-aerc-oauth: {error}", file=sys.stderr)
        sys.exit(1)

    print(f"username={USERNAME}")
    print(f"password={token}")
  '';
in {
  home.packages = [pkgs.gh];

  # enable scrolling in git diff
  home.sessionVariables.DELTA_PAGER = "less -R";

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = gitName;
        email = gitEmail;
      };

      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";
      pull.rebase = true;
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      };
      sendemail = {
        from = "${gitName} <${gitEmail}>";
        smtpAuth = "OAUTHBEARER";
        smtpEncryption = "ssl";
        smtpServer = "smtp.gmail.com";
        smtpServerPort = 465;
        smtpUser = gitEmail;
        confirm = "auto";
      };
      "credential \"smtp://smtp.gmail.com\"" = {
        helper = [
          ""
          "${lib.getExe gitCredentialAercOauth}"
        ];
        username = gitEmail;
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
    ${gitEmail} namespaces="git" ${key}
  '';
}
