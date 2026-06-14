_: {
  home.persistence."/persist" = {
    directories = [
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
      "Zotero"
      ".zotero"
      ".mozilla/firefox"
      ".local/share/zoxide"
      ".tmux/resurrect"
      ".cargo/bin"
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

    files = [
      ".cargo/config.toml"
      ".cargo/credentials.toml"
      ".cargo/env"
    ];
  };
}
