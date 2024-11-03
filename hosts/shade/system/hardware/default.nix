{ lib, config, pkgs, ... }: {
  imports = [ ./bluetooth.nix ./fwupd.nix ./graphics.nix ];
}
