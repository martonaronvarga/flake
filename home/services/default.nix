{ pkgs, config, lib, ...}: {
  imports = [
    ./media/playerctl.nix
    ./system/polkit-agent.nix
    ./wayland/wluma.nix
    ./wayland/waybar.nix
    ./wayland/hypridle.nix
    ./wayland/hyprpaper.nix
  ];
}
