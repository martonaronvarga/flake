{ lib, config, pkgs, ... }: {
  imports = [
    ./fonts.nix
    ./home-manager.nix
    ./xdg.nix
    ./direnv.nix
    ./hyprland.nix
    ./zsh.nix
  ];

  programs = {
    dconf.enable = true;
    gnupg.agent.enable = true;
  };

  environment.systemPackages = with pkgs; [ wget coreutils-full git ];


}
