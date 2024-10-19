{pkgs, ...}: {
  home.packages = with pkgs; [
    exa
    bat
    fzf
    btop
    neofetch
    zip
    unzip
    unrar
    fd
    file
    ripgrep
  ];

  programs = {
    eza.enable = true;
    ssh.enable = true;
  };
}
