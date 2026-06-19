{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      name = "flake-dev";
      packages = with pkgs; [
        # Nix tools
        nix
        nix-tree
        nix-du
        nix-index
        alejandra
        deadnix
        nix-output-monitor
        dix
        statix
        nil
        git-cliff

        # Deployment
        inputs.colmena.packages.${system}.colmena
        inputs.agenix.packages.${system}.default
        openssh

        # General
        git
        coreutils-full
        traceroute
        iproute2
        tcpdump
        jq
      ];

      shellHook = ''
        echo "flake devshell"
        echo "availables:"
        echo "  nix-tree, nix-du, nix-index, alejandra, deadnix, statix, nom, dix, nil, git-cliff"
        echo "  colmena, agenix, openssh"
        echo "  git, coreutils, traceroute, iproute2, tcpdump, jq"
      '';
    };
  };
}
