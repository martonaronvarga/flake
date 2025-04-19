{ lib, inputs, config, pkgs, ... }: {
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
    uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [ kitty wget coreutils-full git ];


}
