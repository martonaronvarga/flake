{pkgs, ...}:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pulsemixer
    pavucontrol

    spotify


    # videos
    vlc
    libvlc
  ];
}
