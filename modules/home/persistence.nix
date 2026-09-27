_: {
  home.persistence."/persist" = {
    directories = [
      "desktop"
      "documents"
      "downloads"
      "music"
      "pictures"
      "public"
      "templates"
      "videos"
      "zotero"
      ".local/share/zoxide"
      ".local/share/FreesmLauncher"
      ".local/share/direnv"
      {
        directory = ".local/share/iamb";
        mode = "0700";
      }
      ".local/state/wayland-appearance"
      {
        directory = ".local/state/mail-sync";
        mode = "0700";
      }
      {
        directory = ".local/share/msmtp";
        mode = "0700";
      }
      ".local/share/wluma"
      {
        directory = ".mail";
        mode = "0700";
      }
      ".cache/aerc"
      ".config/mozilla/firefox"
      ".config/aerc/saved"
      ".tmux/resurrect"
      {
        directory = ".cargo";
        mode = "0700";
      }
      {
        directory = ".gnupg";
        mode = "0700";
      }
      {
        directory = ".password-store";
        mode = "0700";
      }
      {
        directory = ".ssh";
        mode = "0700";
      }
      {
        directory = ".radicle";
        mode = "0700";
      }
      {
        directory = ".local/share/keyrings";
        mode = "0700";
      }
    ];

    files = [];
  };
}
