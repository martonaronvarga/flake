{lib, ...}: {
  services.openssh = {
    enable = true;
    hostKeys = lib.mkDefault [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Machine host identity is system state; user SSH/Git/Agenix keys live in ~/.ssh.
  systemd.tmpfiles.rules = ["d /persist/etc/ssh 0700 root root -"];
}
