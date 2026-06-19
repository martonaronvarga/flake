{pkgs, ...}: let
  shellNavigation = with pkgs; [
    eza
    fd
    ripgrep
    tree
    zoxide
  ];

  fileInspection = with pkgs; [
    bat
    exiftool
    file
  ];

  archivesAndTransfer = with pkgs; [
    croc
    rsync
    unzip
    zip
  ];

  monitoring = with pkgs; [
    btop
    gping
  ];

  terminalFun = with pkgs; [
    figlet
    lolcat
    fastfetch
  ];

  defaultBuildTools = with pkgs; [
    cargo
    gcc
    gnumake
    pkg-config
    shfmt
  ];

  generalUtilities = with pkgs; [
    jq
    libgcc
    tldr
    tmux
  ];
in {
  home.packages =
    shellNavigation
    ++ fileInspection
    ++ archivesAndTransfer
    ++ monitoring
    ++ terminalFun
    ++ defaultBuildTools
    ++ generalUtilities;

  programs = {
    eza.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
