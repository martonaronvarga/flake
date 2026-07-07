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
      ".local/state/oama"
      ".local/share/wluma"
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
        directory = ".ssh";
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
