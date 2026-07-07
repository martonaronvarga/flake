{
  pkgs,
  config,
  lib,
  ...
}: let
  name = "Marton A. Varga";
  account = "martonaronvarga@gmail.com";
  username = builtins.replaceStrings ["@"] ["%40"] account;
  gpgRecipient = "0xD7FC584814D84DA6";

  aercOauthToken = pkgs.writeShellApplication {
    name = "aerc-oauth-token";
    runtimeInputs = [
      pkgs.oama
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
    ];
    text = ''
      set -euo pipefail

      email="${account}"
      errfile="$(mktemp)"
      trap 'rm -f "$errfile"' EXIT

      if token="$(oama access "$email" 2>"$errfile")"; then
        printf '%s\n' "$token"
        exit 0
      fi

      err="$(cat "$errfile")"

      if grep -Eqi 'invalid_grant|expired|revoked|InvalidGrant|reauthor' <<< "$err"; then
        notify-send \
          "Gmail OAuth reauthorization needed" \
          "Run: aerc-oauth-reauth"
      fi

      printf '%s\n' "$err" >&2
      exit 1
    '';
  };

  aercOauthCheck = pkgs.writeShellApplication {
    name = "aerc-oauth-check";
    runtimeInputs = [
      pkgs.oama
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
    ];

    text = ''
      set -euo pipefail

      email="${account}"
      errfile="$(mktemp)"
      trap 'rm -f "$errfile"' EXIT

      # Important: never print the token from a systemd service.
      if oama access "$email" >/dev/null 2>"$errfile"; then
        exit 0
      fi

      err="$(cat "$errfile")"

      if grep -Eqi 'invalid_grant|expired|revoked|InvalidGrant|reauthor' <<< "$err"; then
        notify-send \
          "Gmail OAuth refresh failed" \
          "Run: aerc-oauth-reauth"
      fi

      printf '%s\n' "$err" >&2
      exit 1
    '';
  };

  aercOauthReauth = pkgs.writeShellApplication {
    name = "aerc-oauth-reauth";
    runtimeInputs = [
      pkgs.oama
    ];

    text = ''
      set -euo pipefail
      exec oama authorize google "${account}"
    '';
  };

  patchedAerc = pkgs.aerc.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ../../../../overlays/patches/carddav_query_bearer.patch
      ];
  });
in {
  programs.aerc = {
    enable = true;
    package = patchedAerc;
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
        "d" = ":choose -o y 'Delete this message?' delete-message<Enter>";
        "D" = ":delete<Enter>";
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
      "messages:folder=Archive/d+/.\*" = {
        gi = ":cf Inbox<Enter>";
      };

      view = {
        "/" = ":toggle-key-passthrough<Enter>/";
        "q" = ":close<Enter>";
        "O" = ":open<Enter>";
        "o" = ":open<Enter>";
        "S" = ":save<space>";
        "|" = ":pipe<space>";
        "D" = ":delete<Enter>";
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
        enable-osc8 = true;
      };
      ui = {
        sort = "-r date";
      };
      compose = {
        address-book-cmd = "carddav-query -S martonaronvarga@gmail.com %s";
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
    # templates = {
    # };
    # stylesets = {
    #   default = {
    #     ui = {
    #       "tab.selected.reverse" = "toggle";
    #     };
    #   };
    # };
  };

  xdg.configFile."aerc/accounts.conf".text = ''
    [personal]
    source = imaps+oauthbearer://${username}@imap.gmail.com:993
    outgoing = smtps+oauthbearer://${username}@smtp.gmail.com:465

    source-cred-cmd = ${lib.getExe aercOauthToken}
    outgoing-cred-cmd = ${lib.getExe aercOauthToken}

    carddav-source = https://www.googleapis.com/carddav/v1/principals/${account}/lists/default
    carddav-source-cred-cmd = ${lib.getExe aercOauthToken}

    default = INBOX
    folders-sort = INBOX
    folders-map = ${pkgs.writeText "aerc-gmail-folder-map.txt" ''
      * = [Gmail]/*
    ''}

    postpone = Drafts
    from = ${name} <${account}>
    cache-headers = true
    check-mail = 5m
    copy-to = Sent
    pgp-auto-sign = true
    send-as-utc = true
    signature-cmd = echo -e '\n-- \nMarton Aron Varga\nMetascience Lab\nELTE Eötvös Loránd University\n${account}'
  '';

  home.file.".config/aerc/accounts.conf".force = true;

  home.packages = [
    pkgs.oama
    aercOauthToken
    aercOauthCheck
    aercOauthReauth
  ];

  # look at logs with
  # journalctl --identifier oama --identifier msmtp --identifier fdm -e
  xdg.configFile."oama/config.yaml".text = ''
    encryption:
      tag: GPG
      contents: '${gpgRecipient}'

    services:
      google:
        # Mail for IMAP/SMTP, CardDAV for Google contacts.
        # If Google rejects the carddav scope for your app, use:
        # https://www.googleapis.com/auth/contacts
        auth_scope: 'https://mail.google.com/ https://www.googleapis.com/auth/carddav'

        client_id_cmd: 'cat /run/agenix/aerc-client-id'
        client_secret_cmd: 'cat /run/agenix/aerc-client-secret'
  '';

  systemd.user.services.aerc-oauth-check = {
    Unit = {
      Description = "Check Gmail OAuth token for aerc";
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe aercOauthCheck}";
    };
  };

  systemd.user.timers.aerc-oauth-check = {
    Unit = {
      Description = "Periodically check Gmail OAuth token for aerc";
    };

    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "30m";
      Persistent = true;
    };

    Install.WantedBy = ["timers.target"];
  };
}
