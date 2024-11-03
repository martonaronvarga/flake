{ pkgs, config, ... }: {
  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.usu-pw.path;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
