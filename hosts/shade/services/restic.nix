{
  config,
  infraNetwork,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [restic];

  environment.etc."ssh/known_hosts.d/dusk-restic".text = ''
    ${infraNetwork.dusk.wireguard.address} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrll3wZxB7KTlmTMVXRwpQUNZpjoMIWEO58nM+lwL47
  '';

  services.restic.backups.shade-to-dusk = {
    user = "usu";
    repository = "sftp:usu@${infraNetwork.dusk.wireguard.address}:/persist/backups/restic/shade";
    passwordFile = config.age.secrets.restic-shade-password.path;
    initialize = true;
    paths = [
      "/persist/home/usu"
    ];
    exclude = [
      "/persist/home/usu/.cache"
      "/persist/home/usu/.local/share/Trash"
      "/persist/home/usu/.mozilla/firefox/*/cache2"
      "/persist/home/usu/flake/result"
      "/persist/home/usu/flake/result-*"
      "**/.direnv"
      "**/node_modules"
      "**/target"
    ];
    extraOptions = [
      "sftp.command='ssh usu@${infraNetwork.dusk.wireguard.address} -i /persist/home/usu/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/known_hosts.d/dusk-restic -s sftp'"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    checkOpts = [
      "--read-data-subset=1G"
    ];
    timerConfig = {
      OnCalendar = "03:30";
      RandomizedDelaySec = "45m";
      Persistent = true;
    };
  };
}
