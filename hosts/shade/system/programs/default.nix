{
  lib,
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./fonts.nix
    ./home-manager.nix
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
          binPath = lib.mkForce "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/Hyprland";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [wget coreutils-full git];
}
