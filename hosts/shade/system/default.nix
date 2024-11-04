{ lib, config, pkgs, inputs, ... }: {
  imports = [ ./neovim ./core ./disko ./hardware ./network ./nix ./programs ./services ];
}
