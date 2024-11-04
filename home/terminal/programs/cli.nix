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
  ];

  programs = {
    eza.enable = true;
    ssh.enable = true;
  };
}
