{ pkgs, config, inputs, lib, ...}: {
  programs.aerc = {
    enable = true;
    extraAccounts = {};#TODO
    extraBindings = {};#TODO
    extraConfig = {};#TODO
  };
}
