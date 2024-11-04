{ pkgs, config, inputs, lib, ...}: {
  programs.aerc = {
    enable = true;
    extraAccounts = {};#TODO
    extraBinds = {};#TODO
    extraConfig = {};#TODO
  };
}
