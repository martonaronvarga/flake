{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./programs 
    ./services 
    ./terminal
  ];

  home = {
    username = "usu";
    homeDirectory = "/home/usu";
    stateVersion = "24.11";
    extraOutputsToInstall = ["doc" "devdoc"];
  };

  # disable manuals as nmd fails to build often
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  # let HM manage itself when in standalone mode
  programs.home-manager.enable = true;
  }
