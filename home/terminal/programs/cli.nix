{pkgs, ...}: {
  home.packages = with pkgs; [
    eza
    bat
    fzf
    btop
    neofetch
    zip
    unzip
    fd
    file
    ripgrep
    lolcat
    figlet
    tree
    gping
    croc
    exiftool
    tldr
    vim
    tmux
    rsync
  ];

  programs = {
    eza.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    ssh.enable = true;
  };
}
