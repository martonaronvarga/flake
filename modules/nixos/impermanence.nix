_: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/secrets"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/boot".neededForBoot = true;
  };
}
