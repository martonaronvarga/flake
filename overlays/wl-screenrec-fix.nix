
final: prev: {
    wl-screenrec = prev.wl-screenrec.overrideAttrs (oldAttrs: {
      # Use the specific commit from Nixpkgs
      src = prev.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "a36b4d9ac9e2f4c42b145685a31ac8b58776e8cb";
        hash = "sha256-a36b4d9ac9e2f4c42b145685a31ac8b58776e8cb";
      };
    });
}

