
final: prev: {
    wl-screenrec = prev.wl-screenrec.overrideAttrs (oldAttrs: {
      # Use the specific commit from Nixpkgs
      src = prev.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "a36b4d9ac9e2f4c42b145685a31ac8b58776e8cb";
        hash = "sha256-1m4ic7f0l27pb6g0lfqg2vs8955202zrjl96pcnm4nbmnmcjr8rs";
      };
    });
}

