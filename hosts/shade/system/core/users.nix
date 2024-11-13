{ pkgs, config, ... }: {
  users.mutableUsers = false;
  users.users.usu = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$MdAORfTDZl7kOH5hldBAU.$W8czUSqOHSCSlfEGuSTXzt.aKyQX5iQdfudxxuL6hk7";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
