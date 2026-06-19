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
      ".zotero"
      ".mozilla/firefox"
      ".local/share/zoxide"
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
      ".local/share/direnv"
    ];

    files = [];
  };
}
