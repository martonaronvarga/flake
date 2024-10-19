{ lib, config, pkgs, ...}: {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ ];
  };
}
