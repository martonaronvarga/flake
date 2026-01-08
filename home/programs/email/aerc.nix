{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  # clientid = "/run/agenix/aerc-client-id";
  # clientsecret = "/run/agenix/aerc-client-secret";
  name = "Marton A. Varga";
  username = "martonaronvarga%40gmail.com";
  aercAccountConf = "${config.home.homeDirectory}/.config/aerc/accounts.conf";

  quoteSecret = pkgs.writers.writePython3Bin "aerc-quote-secret" {libraries = [pkgs.python3Packages.setuptools];} ''
    import sys
    import urllib.parse
    from pathlib import Path

    token = Path(sys.argv[1]).read_text().strip()
    print(urllib.parse.quote(token))
  '';
in {
  programs.aerc = {
    enable = true;
    # extraAccounts = {
    #   personal = {
    #     source = "imaps+oauthbearer://${username}@imap.gmail.com?token_endpoint=https%3A%2F%2Foauth2.googleapis.com%2Ftoken&client_id=${clientid}&client_secret=${clientsecret}";
    #     outgoing = "smtps+oauthbearer://${username}@smtp.gmail.com?token_endpoint=https%3A%2F%2Foauth2.googleapis.com%2Ftoken&client_id=${clientid}&client_secret=${clientsecret}";
    #     source-cred-cmd = ''
    #       ${lib.getExe inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default} -d ${toString ../../../secrets/aerc_refresh_token.age} | ${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))'
    #     '';
    #     outgoing-cred-cmd = ''
    #       ${lib.getExe inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default} -d ${toString ../../../secrets/aerc_refresh_token.age} | ${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))'
    #     '';
    #     # To be able to use your google contacts. It only works for personal accounts, not enterprise.
    #     carddav-source = "https://${username}@www.googleapis.com/carddav/v1/principals/martonaronvarga@gmail.com/lists/default";
    #     carddav-source-cred-cmd = ''
    #       ${lib.getExe inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default} -d ${toString ../../../secrets/aerc_refresh_token.age} | ${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))'
    #     '';
    #     default = "INBOX";
    #     folders-sort = "INBOX";
    #     folder-map = "* = [Gmail]/*";
    #     postpone = "Drafts";
    #     from = "${name} <martonaronvarga@gmail.com>";
    #     cache-headers = true;
    #     check-mail = "5m";
    #     copy-to = "Sent";
    #     pgp-auto-sign = true;
    #     pgp-attach-key = true;
    #     send-as-utc = true;
    #     signature-file = ''
    #       --
    #       Marton Aron Varga
    #       Metascience Lab
    #       ELTE Eötvös Loránd University
    #       martonaronvarga@gmail.com
    #     '';
    #   };
    # };
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
        address-book-cmd = "carddav-query -S martonaronvarga %s";
        file-picker-cmd = "yazi --choser-file %f";
        reply-to-self = false;
        no-attachment-warning = "^[^>]\*attach(ed|ment)";
        format-flowed = true;
      };
      multipart-converters = ''
        text/html=${pkgs.pandoc}/bin -f markdown -t html --standalone
      '';
      filters = ''
        text/plain=fold -w $(tput cols) | colorize
        subject,~Git(hub|lab)=lolcat -f
        text/html=${pkgs.pandoc}/bin -f html -t plain
        text/calendar=calendar
        message/delivery-status=colorize
        message/rfc822=colorize
        .filename,~.*\.csv=column -t --separator=","
      '';
      hooks = {
        mail-received = ''
          notify-send "[$AERC_ACCOUNT/$AERC_FOLDER] New mail from $AERC_FROM_NAME" "$AERC_SUBJECT"
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

  home.activation.generateAercAccountsConf = lib.hm.dag.entryAfter ["checkLinkTargets"] ''
    mkdir -p $HOME/.config/aerc
    CLIENT_ID=$(${quoteSecret}/bin/aerc-quote-secret /run/agenix/aerc-client-id)
    CLIENT_SECRET=$(${quoteSecret}/bin/aerc-quote-secret /run/agenix/aerc-client-secret)

    cat > ${aercAccountConf} <<EOF
    [personal]
    source = imaps+oauthbearer://${username}@imap.gmail.com?token_endpoint=https%3A%2F%2Foauth2.googleapis.com%2Ftoken&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET
    outgoing = smpts+oauthbearer://${username}@imap.gmail.com?token_endpoint=https%3A%2F%2Foauth2.googleapis.com%2Ftoken&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET
    source-cred-cmd = ${lib.getExe quoteSecret} /run/agenix/aerc-refresh-token
    outgoing-cred-cmd = ${lib.getExe quoteSecret} /run/agenix/aerc-refresh-token
    carddav-source = https://${username}@www.googleapis.com/carddav/v1/principals/martonaronvarga@gmail.com/lists/default
    carddav-source-cred-cmd = ${lib.getExe quoteSecret} /run/agenix/aerc-refresh-token
    default = INBOX
    folders-sort = INBOX
    folders-map = ${pkgs.writeText "map.txt" "* = [Gmail]/*"}
    postpone = Drafts
    from = ${name} <martonaronvarga@gmail.com>
    cache-headers = true
    check-mail = 5m
    copy-to = Sent
    pgp-auto-sign = true
    pgp-attach-key = true
    send-as-utc = true
    signature-cmd = echo -e '\n-- \nMarton Aron Varga\nMetascience Lab\nELTE Eötvös Loránd University\nmartonaronvarga@gmail.com'
    EOF
    chmod 600 ${aercAccountConf}
  '';
}
