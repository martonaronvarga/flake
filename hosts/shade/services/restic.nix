{
  config,
  infraNetwork,
  ...
}: {
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
      "sftp.command='ssh usu@${infraNetwork.dusk.wireguard.address} -J ${infraNetwork.gloam.sshUser}@${infraNetwork.gloam.publicIp} -i /persist/home/usu/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/persist/home/usu/.ssh/known_hosts -s sftp'"
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
