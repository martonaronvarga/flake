{pkgs, ...}: {
  boot.kernelParams = ["console=tty1" "console=ttyS0,115200" "nomodeset"];

  services = {
    xserver.enable = false;
    pipewire.enable = false;
    pulseaudio.enable = false;
  };

  console = {
    font = "Lat2-Terminus16";
    keymap = "us";
  };

  environment.noXlibs = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    tmux
    coreutils-full
  ];

  # Reduce closure size
  documentation = {
    enable = false;
    nixos.enable = false;
  };
}
