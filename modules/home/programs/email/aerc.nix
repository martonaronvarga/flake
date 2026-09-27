{
  inventory,
  pkgs,
  lib,
  ...
}: let
  inherit (inventory) mail;
  name = "Marton A. Varga";
  account = mail.sender;
  ttkAccount = "varga.marton.aron@ttk.hu";
  ttkUsername = ttkAccount;
  ttkPasswordPath = "/run/agenix/ttk-mail-password";
  # Keep legacy TTK polling paused while Exchange Online access is unresolved.
  workMailSyncEnabled = false;
  # Inbound Cloudflare Email Routing aliases for the Gmail account. Keep Gmail
  # as the SMTP sender unless a domain alias is verified in Gmail "send mail as".
  inherit (mail) aliases;
  username = builtins.replaceStrings ["@"] ["%40"] account;
  signingKey = "CB9E4B52941046921DB1C2A52C72BBA1595A735E";
  accountFromFilename = ''{{index (.Filename | split "/") 4}}'';

  aercOauthToken = import ./oauth-token.nix {inherit pkgs lib account;};
  ttkOauthToken = import ./oauth-token.nix {
    inherit pkgs lib;
    account = ttkAccount;
    name = "ttk-oauth-token";
    label = "TTK Microsoft 365";
    reauthCommand = "ttk-oauth-reauth";
  };

  ttkOauthReauth = pkgs.writeShellApplication {
    name = "ttk-oauth-reauth";
    runtimeInputs = [pkgs.oama];
    text = ''
      set -euo pipefail
      exec oama authorize microsoft ${lib.escapeShellArg ttkAccount} --device
    '';
  };

  ttkOauthCheck = pkgs.writeShellApplication {
    name = "ttk-oauth-check";
    text = ''
      ${lib.getExe ttkOauthToken} >/dev/null
    '';
  };

  aercOauthCheck = pkgs.writeShellApplication {
    name = "aerc-oauth-check";
    text = ''
      # The provider owns refresh and safe diagnostics; never log its token.
      ${lib.getExe aercOauthToken} >/dev/null
    '';
  };

  aercOauthReauth = pkgs.writeShellApplication {
    name = "aerc-oauth-reauth";
    runtimeInputs = [
      pkgs.oama
    ];

    text = ''
      set -euo pipefail
      exec oama authorize google ${lib.escapeShellArg account}
    '';
  };

  ttkMailPassword = pkgs.writeShellApplication {
    name = "ttk-mail-password";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -euo pipefail

      password_file=${lib.escapeShellArg ttkPasswordPath}
      if [[ ! -r "$password_file" ]]; then
        printf 'TTK mail credential is unavailable: %s\n' "$password_file" >&2
        exit 1
      fi

      exec cat "$password_file"
    '';
  };

  ttkMailCheck = pkgs.writers.writePython3Bin "ttk-mail-check" {} ''
    import imaplib
    import smtplib
    import ssl
    import sys
    from pathlib import Path

    USERNAME = "${ttkUsername}"
    PASSWORD_PATH = Path("${ttkPasswordPath}")


    try:
        password = PASSWORD_PATH.read_text().rstrip("\r\n")
        context = ssl.create_default_context()

        with imaplib.IMAP4_SSL(
            "imap.ttk.hu", 993, ssl_context=context, timeout=20
        ) as imap:
            imap.login(USERNAME, password)
            status, folders = imap.list()
            if status != "OK":
                raise RuntimeError(f"IMAP LIST failed: {status}")
            folder_count = len(folders or [])

        with smtplib.SMTP_SSL(
            "smtp.ttk.hu", 465, context=context, timeout=20
        ) as smtp:
            smtp.login(USERNAME, password)
            code, _ = smtp.noop()
            if code != 250:
                raise RuntimeError(f"SMTP NOOP failed: {code}")
    except Exception as error:
        print(f"TTK mail check failed: {error}", file=sys.stderr)
        sys.exit(1)

    print(f"TTK mail authentication is healthy ({folder_count} IMAP folders).")
  '';

  patchedAerc = pkgs.aerc.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ../../../../overlays/patches/carddav_query_bearer.patch
      ];
  });

  folderMap = pkgs.writeText "aerc-gmail-folder-map" ''
    Archive = [Gmail]/All Mail
    Drafts = [Gmail]/Drafts
    Sent = [Gmail]/Sent Mail
    Spam = [Gmail]/Spam
    Trash = [Gmail]/Bin
  '';

  notmuchQueryMap = pkgs.writeText "aerc-notmuch-query-map" ''
    inbox=tag:inbox
    unread=tag:unread
    flagged=tag:flagged
    work=path:work/**
    recent=date:7d..
  '';

  mailSyncPackage = pkgs.isync.override {
    withCyrusSaslXoauth2 = true;
  };

  mkPullChannel = farPattern: nearPattern: {
    inherit farPattern nearPattern;
    extraConfig = {
      CopyArrivalDate = true;
      Create = "Near";
      Expunge = "Near";
      Remove = "None";
      Sync = "Pull";
      SyncState = "*";
    };
  };

  aercAddressBook = pkgs.writers.writePython3Bin "aerc-address-book" {} ''
    import json
    import os
    import subprocess
    import sys
    from pathlib import Path


    query = " ".join(sys.argv[1:]).strip().casefold()
    contacts = {}
    carddav_package = "${patchedAerc}"
    notmuch_package = "${pkgs.notmuch}"


    def add_contact(address, display_name=""):
        address = address.strip()
        display_name = display_name.replace("\t", " ").replace("\n", " ").strip()
        if not address or "@" not in address:
            return
        matches_address = query in address.casefold()
        matches_name = query in display_name.casefold()
        if query and not matches_address and not matches_name:
            return
        contacts.setdefault(address.casefold(), (address, display_name))


    # Prefer the explicit contact name from CardDAV when it is available. A
    # short timeout keeps completion useful when the network is down.
    try:
        carddav = subprocess.run(
            [
                carddav_package + "/bin/carddav-query",
                "-S",
                "personal",
                query,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=3,
        )
        for line in carddav.stdout.splitlines():
            address, _, display_name = line.partition("\t")
            add_contact(address, display_name)
    except (OSError, subprocess.TimeoutExpired):
        pass

    # Correspondents from the local archive remain available offline. Sender
    # lookup is indexed; recipient lookup is limited to messages tagged sent.
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    notmuch_config = config_home / "notmuch/default/config"
    if notmuch_config.is_file():
        environment = os.environ.copy()
        environment["NOTMUCH_CONFIG"] = str(notmuch_config)
        commands = [
            ["--output=sender", "*"],
            ["--output=recipients", "tag:sent"],
        ]
        for output_option, search_query in commands:
            try:
                result = subprocess.run(
                    [
                        notmuch_package + "/bin/notmuch",
                        "address",
                        "--format=json",
                        output_option,
                        "--deduplicate=address",
                        search_query,
                    ],
                    check=False,
                    capture_output=True,
                    text=True,
                    timeout=2,
                    env=environment,
                )
                if result.returncode == 0:
                    for contact in json.loads(result.stdout):
                        add_contact(
                            contact.get("address", ""),
                            contact.get("name", ""),
                        )
            except (json.JSONDecodeError, OSError, subprocess.TimeoutExpired):
                pass

    for address, display_name in list(contacts.values())[:100]:
        print(f"{address}\t{display_name}")
  '';

  mkMailSubmit = accountName:
    pkgs.writeShellApplication {
      name = "mail-submit-${accountName}";
      runtimeInputs = [pkgs.msmtp];
      text = ''
        set -euo pipefail

        export MSMTPQ_Q="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue/${accountName}"
        export MSMTPQ_LOG="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue.log"
        export EMAIL_CONN_TEST=x
        export EMAIL_QUEUE_QUIET=t

        install -d -m 0700 "$MSMTPQ_Q"
        exec msmtpq --account=${accountName} --read-envelope-from "$@"
      '';
    };

  mailSubmitPersonal = mkMailSubmit "personal";
  mailSubmitWork = mkMailSubmit "work";

  mailQueueFlush = pkgs.writeShellApplication {
    name = "mail-queue-flush";
    runtimeInputs = [pkgs.msmtp];
    text = ''
      set -euo pipefail

      account="''${1:-}"
      case "$account" in
        personal | work) ;;
        *)
          printf 'Usage: mail-queue-flush {personal|work}\n' >&2
          exit 2
          ;;
      esac

      export MSMTPQ_Q="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue/$account"
      export MSMTPQ_LOG="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue.log"
      export EMAIL_CONN_TEST=x
      export EMAIL_QUEUE_QUIET=t

      install -d -m 0700 "$MSMTPQ_Q"
      exec msmtp-queue -r
    '';
  };

  mailQueueStatus = pkgs.writeShellApplication {
    name = "mail-queue-status";
    runtimeInputs = [pkgs.msmtp];
    text = ''
      set -euo pipefail

      for account in personal work; do
        export MSMTPQ_Q="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue/$account"
        export MSMTPQ_LOG="''${XDG_DATA_HOME:-$HOME/.local/share}/msmtp/queue.log"
        printf '%s queue:\n' "$account"
        msmtp-queue -d
      done
    '';
  };

  mailSync = pkgs.writeShellApplication {
    name = "mail-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
      pkgs.notmuch
      pkgs.util-linux
      mailSyncPackage
    ];
    text = ''
      set -euo pipefail

      account="''${1:-}"
      tier="''${2:-fast}"
      case "$account:$tier" in
        personal:fast | personal:slow | work:fast | work:slow) ;;
        *)
          printf 'Usage: mail-sync {personal|work} [fast|slow]\n' >&2
          exit 2
          ;;
      esac

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/mail-sync"
      mkdir -p "$state_dir"
      chmod 0700 "$state_dir"
      exec 9>"$state_dir/$account.lock"
      flock 9
      export NOTMUCH_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/notmuch/default/config"
      sync_log="$(mktemp)"
      trap 'rm -f "$sync_log"' EXIT

      sync_failed=false
      if ! mbsync "$account-$tier" 2>&1 | tee "$sync_log"; then
        sync_failed=true
      fi
      if grep -q '^Error:' "$sync_log"; then
        sync_failed=true
      fi

      if [[ "$sync_failed" == true ]]; then
        notify-send \
          "Mail synchronization failed ($account-$tier)" \
          "Run: journalctl --user -u mail-sync-$account-$tier.service -e" \
          || true
        exit 1
      fi

      flock "$state_dir/notmuch.lock" notmuch new
    '';
  };

  mailSyncEnable = pkgs.writeShellApplication {
    name = "mail-sync-enable";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -euo pipefail

      account="''${1:-}"
      case "$account" in
        personal | work) ;;
        *)
          printf 'Usage: mail-sync-enable {personal|work}\n' >&2
          exit 2
          ;;
      esac

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/mail-sync"
      install -d -m 0700 "$state_dir"
      touch "$state_dir/$account.enabled"
      printf '%s mail synchronization timer enabled.\n' "$account"
    '';
  };

  mailCheckUnified = pkgs.writeShellApplication {
    name = "mail-check-unified";
    runtimeInputs = [pkgs.systemd];
    text = ''
      set -euo pipefail

      # Starting an already-running oneshot is coalesced by systemd, so this
      # safely shares the fast channels with their background timers.
      systemctl --user start \
        mail-sync-personal-fast.service \
        mail-sync-work-fast.service
    '';
  };

  ttkMailMonitor = pkgs.writeShellApplication {
    name = "ttk-mail-monitor";
    runtimeInputs = [
      pkgs.libnotify
      ttkMailCheck
    ];
    text = ''
      set -euo pipefail

      if ! error="$(ttk-mail-check 2>&1)"; then
        printf '%s\n' "$error" >&2
        notify-send \
          "TTK mail authentication failed" \
          "Run: ttk-mail-check; then rotate the agenix secret if needed" \
          || true
        exit 1
      fi
    '';
  };

  mkMailSyncService = accountName: tier: {
    Unit = {
      Description = "Synchronize ${accountName} ${tier} mail channels";
      After = ["graphical-session.target"];
      ConditionPathExists = "%h/.local/state/mail-sync/${accountName}.enabled";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe mailSync} ${accountName} ${tier}";
    };
  };

  mkMailSyncTimer = accountName: tier: delay: interval: {
    Unit.Description = "Periodically synchronize ${accountName} ${tier} mail channels";
    Timer = {
      OnBootSec = delay;
      OnUnitActiveSec = interval;
      RandomizedDelaySec = "30s";
      Persistent = true;
    };
    Install.WantedBy = lib.optionals (accountName != "work" || workMailSyncEnabled) ["timers.target"];
  };

  mkMailQueueService = accountName: {
    Unit = {
      Description = "Retry queued ${accountName} mail";
      After = ["network-online.target"];
      ConditionPathExistsGlob = "%h/.local/share/msmtp/queue/${accountName}/*.mail";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe mailQueueFlush} ${accountName}";
    };
  };

  mkMailQueueTimer = accountName: delay: {
    Unit.Description = "Periodically retry queued ${accountName} mail";
    Timer = {
      OnBootSec = delay;
      OnUnitActiveSec = "2m";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
in {
  accounts.email = {
    maildirBasePath = ".mail";
    accounts = {
      personal = {
        primary = true;
        flavor = "gmail.com";
        address = account;
        inherit aliases;
        realName = name;
        userName = account;
        passwordCommand = lib.getExe aercOauthToken;
        folders = {
          inbox = "INBOX";
          sent = "Sent";
          drafts = "Drafts";
          trash = "Trash";
        };
        mbsync = {
          enable = true;
          create = "maildir";
          remove = "none";
          expunge = "none";
          groups = {
            personal-fast.channels = {
              inbox = mkPullChannel "INBOX" "INBOX";
              drafts = mkPullChannel "[Gmail]/Drafts" "Drafts";
            };
            personal-slow.channels = {
              sent = mkPullChannel "[Gmail]/Sent Mail" "Sent";
              spam = mkPullChannel "[Gmail]/Spam" "Spam";
              trash = mkPullChannel "[Gmail]/Bin" "Trash";
              archive = mkPullChannel "[Gmail]/All Mail" "Archive";
            };
          };
          extraConfig = {
            account.AuthMechs = "XOAUTH2";
          };
        };
        imapnotify = {
          enable = true;
          boxes = ["INBOX"];
          onNotify = "${lib.getExe mailSync} personal fast";
          extraArgs = ["-wait" "5"];
          extraConfig.xoAuth2 = true;
        };
        msmtp = {
          enable = true;
          extraConfig.auth = "oauthbearer";
        };
        notmuch.enable = true;
      };

      work = {
        address = ttkAccount;
        realName = name;
        userName = ttkUsername;
        passwordCommand = lib.getExe ttkMailPassword;
        folders = {
          inbox = "INBOX";
          sent = "Sent";
          drafts = "Drafts";
          trash = "Trash";
        };
        imap = {
          host = "imap.ttk.hu";
          port = 993;
          authentication = "plain";
          tls.enable = true;
        };
        smtp = {
          host = "smtp.ttk.hu";
          port = 465;
          authentication = "login";
          tls.enable = true;
        };
        mbsync = {
          enable = true;
          create = "maildir";
          remove = "none";
          expunge = "none";
          groups = {
            work-fast.channels = {
              inbox = mkPullChannel "INBOX" "INBOX";
              drafts = mkPullChannel "Drafts" "Drafts";
            };
            work-slow.channels = {
              sent = mkPullChannel "Sent" "Sent";
              trash = mkPullChannel "Trash" "Trash";
              junk = mkPullChannel "Junk" "Junk";
              archive = mkPullChannel "Archive" "Archive";
            };
          };
          extraConfig = {
            account.AuthMechs = "PLAIN";
          };
        };
        imapnotify = {
          enable = workMailSyncEnabled;
          boxes = ["INBOX"];
          onNotify = "${lib.getExe mailSync} work fast";
          extraArgs = ["-wait" "5"];
        };
        msmtp = {
          enable = true;
          extraConfig.auth = "login";
        };
        notmuch.enable = true;
      };
    };
  };

  programs = {
    mbsync = {
      enable = true;
      package = mailSyncPackage;
    };

    msmtp.enable = true;

    notmuch = {
      enable = true;
      new.tags = ["new"];
      maildir.synchronizeFlags = true;
      search.excludeTags = ["deleted" "spam"];
      hooks.postNew = ''
        notmuch tag +inbox -- 'path:personal/INBOX/** or path:work/INBOX/**'
        notmuch tag -inbox -- 'tag:inbox and not path:personal/INBOX/** and not path:work/INBOX/**'
        notmuch tag +sent -- 'path:personal/Sent/** or path:work/Sent/**'
        notmuch tag -sent -- 'tag:sent and not path:personal/Sent/** and not path:work/Sent/**'
        notmuch tag +draft -- 'path:personal/Drafts/** or path:work/Drafts/**'
        notmuch tag -draft -- 'tag:draft and not path:personal/Drafts/** and not path:work/Drafts/**'
        notmuch tag +deleted -- 'path:personal/Trash/** or path:work/Trash/**'
        notmuch tag -deleted -- 'tag:deleted and not path:personal/Trash/** and not path:work/Trash/**'
        notmuch tag +spam -- 'path:personal/Spam/** or path:work/Junk/**'
        notmuch tag -spam -- 'tag:spam and not path:personal/Spam/** and not path:work/Junk/**'
        notmuch tag -new -- tag:new
      '';
    };

    aerc = {
      enable = true;
      package = patchedAerc;

      extraAccounts = {
        personal = {
          source = "imaps+oauthbearer://${username}@imap.gmail.com:993";
          outgoing = lib.getExe mailSubmitPersonal;

          source-cred-cmd = lib.getExe aercOauthToken;

          carddav-source = "https+oauthbearer://${username}@www.googleapis.com/carddav/v1/principals/${account}/lists/default";
          carddav-source-cred-cmd = lib.getExe aercOauthToken;

          default = "INBOX";
          folders-sort = "INBOX,Drafts,Sent,Archive,Spam,Trash";

          folder-map = "${folderMap}";
          postpone = "Drafts";
          copy-to = "Sent";
          archive = "Archive";

          from = "${name} <${account}>";
          aliases = lib.concatMapStringsSep "," (alias: "${name} <${alias}>") aliases;
          cache-headers = true;
          check-mail = "5m";

          pgp-auto-sign = true;
          pgp-key-id = signingKey;
          send-as-utc = true;

          signature-cmd = ''
            echo -e '\n-- \nMarton Aron Varga\nMetascience Lab\nELTE Eötvös Loránd University\n${account}'
          '';
        };
        work = {
          source = "imaps://${ttkUsername}@imap.ttk.hu:993";
          outgoing = lib.getExe mailSubmitWork;

          source-cred-cmd = lib.getExe ttkMailPassword;

          default = "INBOX";
          folders-sort = "INBOX,Sent,Drafts,Archive,Junk,Trash";
          postpone = "Drafts";
          copy-to = "Sent";
          archive = "Archive";

          from = "${name} <${ttkAccount}>";
          cache-headers = true;
          check-mail = "5m";

          pgp-auto-sign = true;
          pgp-key-id = signingKey;
          send-as-utc = true;

          signature-cmd = ''
            echo -e '\n-- \nMarton Aron Varga\nHUN-REN TTK\n${ttkAccount}'
          '';
        };
        unified = {
          source = "notmuch://";
          query-map = toString notmuchQueryMap;
          default = "inbox";
          folders-sort = "inbox,unread,flagged,recent,work";

          from = "${name} <${account}>";
          aliases = lib.concatMapStringsSep "," (alias: "${name} <${alias}>") aliases;
          check-mail = "2m";
          check-mail-cmd = lib.getExe mailCheckUnified;
          check-mail-timeout = "1m";
        };
      };

      extraBinds = {
        global = {
          "\\[t" = ":prev-tab<Enter>";
          "\\]t" = ":next-tab<Enter>";
          "<C-t>" = ":term<Enter>";
          "<C-?>" = ":help keys<Enter>";
          "<C-c>" = ":prompt 'Quit?' quit<Enter>";
          "<C-q>" = ":prompt 'Quit?' quit<Enter>";
          "<C-z>" = ":suspend<Enter>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
          "?" = ":help keys<Enter>";
        };
        messages = {
          # Defaults?
          "j" = ":next<Enter>";
          "k" = ":prev<Enter>";
          "J" = ":next-folder<Enter>";
          "K" = ":prev-folder<Enter>";
          "n" = ":next-result<Enter>";
          "N" = ":prev-result<Enter>";
          "h" = ":prev-tab<Enter>";
          "l" = ":next-tab<Enter>";

          "H" = ":collapse-folder<Enter>";
          "L" = ":expand-folder<Enter>";

          "v" = ":mark -t<Enter>";
          "x" = ":mark -t<Enter>:next<Enter>";
          "V" = ":mark -v<Enter>";

          "q" = ":quit<Enter>";
          "cf" = ":cf path:mailbox/** and<space>";

          "g" = ":select 0<Enter>";
          "G" = ":select -1<Enter>";

          "T" = ":toggle-threads<Enter>";
          "zc" = ":fold<Enter>";
          "zo" = ":unfold<Enter>";
          "za" = ":fold -t<Enter>";
          "zM" = ":fold -a<Enter>";
          "zR" = ":unfold -a<Enter>";
          "<tab>" = ":fold -t<Enter>";
          "<Enter>" = ":view<Enter>";
          "d" = ":choose -o y 'Move this message to Trash?' move Trash<Enter>";
          "D" = ":move Trash<Enter>";
          "a" = ":archive flat<Enter>";
          "A" = ":unmark -a<Enter>:mark -T<Enter>:archive flat<Enter>";
          "C" = ":compose<Enter>";
          "b" = ":bounce<space>";

          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";

          "c" = ":cf<space>";
          "$" = ":term<space>";
          "!" = ":term<space>";
          "|" = ":pipe<space>";

          "/" = ":search<space>";
          "\\" = ":filter<space>";
          "<Esc>" = ":clear<Enter>";

          "s" = ":split<Enter>";
          "S" = ":vsplit<Enter>";

          "pl" = ":patch list<Enter>";
          "pa" = ":patch apply <Tab>";
          "pd" = ":patch drop <Tab>";
          "pb" = ":patch rebase<Enter>";
          "pt" = ":patch term<Enter>";
          "ps" = ":patch switch <Tab>";
        };
        "messages:folder=Drafts" = {
          "<Enter>" = ":recall<Enter>";
        };
        "messages:folder=Trash" = {
          "d" = ":choose -o y 'Permanently delete this message?' delete-message<Enter>";
          "D" = ":delete<Enter>";
        };
        "messages:folder=Archive/d+/.\*" = {
          gi = ":cf Inbox<Enter>";
        };
        "messages:account=unified" = {
          "rr" = ":reply -a -A ${accountFromFilename}<Enter>";
          "rq" = ":reply -aq -A ${accountFromFilename}<Enter>";
          "Rr" = ":reply -A ${accountFromFilename}<Enter>";
          "Rq" = ":reply -q -A ${accountFromFilename}<Enter>";
          "f" = ":forward -A ${accountFromFilename}<Enter>";
          "C" = ":echo Use Cp (personal) or Cw (work) from unified search.<Enter>";
          "Cp" = ":switch-account personal<Enter>:compose<Enter>";
          "Cw" = ":switch-account work<Enter>:compose<Enter>";
          "a" = ":echo Switch to the source account before archiving.<Enter>";
          "A" = ":echo Switch to the source account before archiving.<Enter>";
          "d" = ":echo Switch to the source account before deleting.<Enter>";
          "D" = ":echo Switch to the source account before deleting.<Enter>";
        };

        view = {
          "/" = ":toggle-key-passthrough<Enter>/";
          "q" = ":close<Enter>";
          "O" = ":open<Enter>";
          "o" = ":open<Enter>";
          "S" = ":save<space>";
          "|" = ":pipe<space>";
          "D" = ":move Trash<Enter>";
          "A" = ":archive flat<Enter>";

          "<C-y>" = ":copy-link <space>";
          "<C-l>" = ":open-link <space>";

          "f" = ":forward<Enter>";
          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";

          "H" = ":toggle-headers<Enter>";
          "<C-e>" = ":prev-part<Enter>";
          "<C-n>" = ":next-part<Enter>";
          "J" = ":next<Enter>";
          "K" = ":prev<Enter>";
        };
        "view:account=unified" = {
          "rr" = ":reply -a -A ${accountFromFilename}<Enter>";
          "rq" = ":reply -aq -A ${accountFromFilename}<Enter>";
          "Rr" = ":reply -A ${accountFromFilename}<Enter>";
          "Rq" = ":reply -q -A ${accountFromFilename}<Enter>";
          "f" = ":forward -A ${accountFromFilename}<Enter>";
          "A" = ":echo Switch to the source account before archiving.<Enter>";
          "D" = ":echo Switch to the source account before deleting.<Enter>";
        };
        "view:folder=Trash" = {
          "D" = ":delete<Enter>";
        };
        "view::passthrough" = {
          "$noinherit" = true;
          "$ex" = "<C-x>";
          "<Esc>" = ":toggle-key-passthrough<Enter>";
        };
        compose = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "$complete" = "<C-o>";
          "<C-j>" = ":next-field<Enter>";
          "<C-k>" = ":prev-field<Enter>";
          "<C-Left>" = ":switch-account -p<Enter>";
          "<C-Right>" = ":switch-account -n<Enter>";
          "<tab>" = ":next-field<Enter>";
          "<backtab>" = ":prev-field<Enter>";
          "<C-PgUp>" = ":prev-tab<Enter>";
          "<C-PgDn>" = ":next-tab<Enter>";
        };
        "compose::editor" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-k>" = ":prev-field<Enter>";
          "<C-j>" = ":next-field<Enter>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
        };
        "compose::editor:folder=aerc" = {
          y = ":send -t aerc";
        };
        "compose::review" = {
          "y" = ":send<Enter>";
          "n" = ":abort<Enter>";
          "s" = ":sign<Enter>";
          "x" = ":encrypt<Enter>";
          "v" = ":preview<Enter>";
          "p" = ":postpone<Enter>";
          "q" = ":choose -o d discard abort -o p postpone postpone<Enter>";
          "e" = ":edit<Enter>";
          "a" = ":attach<space>";
          "d" = ":detach<space>";
          "H" = ":multipart text/html<Enter>";
        };
        terminal = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
        };
      };
      extraConfig = {
        general = {
          default-menu-cmd = "fzf --tmux";
          default-save-path = "~/.config/aerc/saved";
          pgp-provider = "gpg";
          term = "xterm-kitty";
          unsafe-accounts-conf = true;
        };

        ui = {
          sort = "-r date";
        };

        compose = {
          address-book-cmd = "${lib.getExe aercAddressBook} '%s'";
          file-picker-cmd = "yazi --chooser-file %f";
          reply-to-self = false;
          no-attachment-warning = "^[^>]*attach(ed|ment)";
          format-flowed = true;
        };

        multipart-converters = ''
          text/html=${lib.getExe pkgs.pandoc} -f markdown -t html --standalone
        '';

        filters = ''
          text/plain=fold -w $(tput cols) | colorize
          subject,~Git(hub|lab)=lolcat -f
          text/html=${lib.getExe pkgs.pandoc} -f html -t plain
          text/calendar=calendar
          message/delivery-status=colorize
          message/rfc822=colorize
          .filename,~.*\.csv=column -t --separator=","
        '';

        hooks = {
          mail-received = ''
            dunstify "[$AERC_ACCOUNT/$AERC_FOLDER] New mail from $AERC_FROM_NAME" "$AERC_SUBJECT"
          '';
        };
      };
    };
  };

  services.imapnotify.enable = true;

  home.packages = [
    pkgs.oama
    aercOauthToken
    aercOauthCheck
    aercOauthReauth
    ttkOauthToken
    ttkOauthReauth
    ttkOauthCheck
    ttkMailCheck
    ttkMailMonitor
    ttkMailPassword
    mailSync
    mailSyncEnable
    mailCheckUnified
    mailSubmitPersonal
    mailSubmitWork
    mailQueueFlush
    mailQueueStatus
    aercAddressBook
  ];

  xdg.configFile."aerc/notmuch-query-map".source = notmuchQueryMap;

  # look at logs with
  # journalctl --identifier oama --identifier msmtp --identifier fdm -e
  xdg.configFile."oama/config.yaml".text = ''
    encryption:
      tag: KEYRING

    services:
      google:
        # Mail for IMAP/SMTP, CardDAV for Google contacts.
        # If Google rejects the carddav scope for your app, use:
        # https://www.googleapis.com/auth/contacts
        auth_scope: 'https://mail.google.com/ https://www.googleapis.com/auth/carddav'

        client_id_cmd: 'cat /run/agenix/aerc-client-id'
        client_secret_cmd: 'cat /run/agenix/aerc-client-secret'

      microsoft:
        client_id: '45bddbb4-33cc-442c-93d2-4b9e95c8844a'
        tenant: '2cc28feb-2fc7-4e24-802c-86ac0a251cfb'
        auth_scope: 'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access'
  '';

  systemd.user.services = {
    aerc-oauth-check = {
      Unit = {
        Description = "Check Gmail OAuth token for aerc";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe aercOauthCheck}";
      };
    };

    mail-sync-personal-fast = mkMailSyncService "personal" "fast";
    mail-sync-personal-slow = mkMailSyncService "personal" "slow";
    mail-sync-work-fast = mkMailSyncService "work" "fast";
    mail-sync-work-slow = mkMailSyncService "work" "slow";

    mail-queue-flush-personal = mkMailQueueService "personal";
    mail-queue-flush-work = mkMailQueueService "work";

    ttk-mail-check = {
      Unit = {
        Description = "Check TTK IMAP and SMTP authentication";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe ttkMailMonitor;
      };
    };
  };

  systemd.user.timers = {
    aerc-oauth-check = {
      Unit.Description = "Periodically check Gmail OAuth token for aerc";
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = "30m";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };

    mail-sync-personal-fast = mkMailSyncTimer "personal" "fast" "2m" "2m";
    mail-sync-personal-slow = mkMailSyncTimer "personal" "slow" "5m" "15m";
    mail-sync-work-fast = mkMailSyncTimer "work" "fast" "3m" "2m";
    mail-sync-work-slow = mkMailSyncTimer "work" "slow" "6m" "15m";

    mail-queue-flush-personal = mkMailQueueTimer "personal" "2m";
    mail-queue-flush-work = mkMailQueueTimer "work" "3m";

    ttk-mail-check = {
      Unit.Description = "Periodically check TTK IMAP and SMTP authentication";
      Timer = {
        OnBootSec = "5m";
        OnUnitActiveSec = "30m";
        RandomizedDelaySec = "1m";
        Persistent = true;
      };
      Install.WantedBy = lib.optionals workMailSyncEnabled ["timers.target"];
    };
  };

  # Credential recovery:
  #   agenix -e secrets/ttk_mail_password.age
  #   nh os switch .#shade
  #   ttk-mail-check
  # OAuth recovery:
  #   aerc-oauth-reauth
  #   systemctl --user start mail-sync-personal-fast.service
  # Enable scheduled sync only after a successful manual first run:
  #   mail-sync work fast && mail-sync work slow && mail-sync-enable work
  #   mail-sync personal fast && mail-sync personal slow && mail-sync-enable personal
}
