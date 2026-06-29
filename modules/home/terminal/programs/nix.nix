{pkgs, ...}:
# nix tooling
{
  home.packages = with pkgs; [
    alejandra # formatting
    deadnix # dead code
    nixd # language server
    statix # lints

    nix-output-monitor # pretty outputs
    dix # upgrade diffs
    nix-tree # trees
    nix-diff # nix diffs
    nix-index # database
    nix-fast-build # parallel build

    nixfmt # formatting
    yq # yaml/xml/toml for jq
    age # crypto
    comma # run whatever using: `, <cmd> <opts>`
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    config = {
      global = {
        log_format = "-";
        log_filter = "^$";
      };
    };
  };
}
