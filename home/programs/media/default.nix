{pkgs, lib, ...}:
# media - control and enjoy audio/video
{
  pkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "spotify"
  ];

  home.packages = with pkgs; [
    # audio control
    pulsemixer
    pavucontrol

    # videos
    vlc
    libvlc
  ];
}
