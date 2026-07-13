{pkgs, ...}: {
  environment.systemPackages = with pkgs; [restic];

  systemd.tmpfiles.rules = [
    "d /persist/backups 0755 root root -"
    "d /persist/backups/forgejo 0750 forgejo forgejo -"
    "d /persist/backups/restic 0750 usu users -"
    "d /persist/backups/restic/shade 0750 usu users -"
    "d /persist/backups/vaultwarden 0770 vaultwarden vaultwarden -"
  ];
}
