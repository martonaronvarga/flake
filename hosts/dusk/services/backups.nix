{pkgs, ...}: {
  environment.systemPackages = with pkgs; [restic];

  systemd.tmpfiles.rules = [
    "d /persist/backups 0755 root root -"
    "d /persist/backups/forgejo 0750 forgejo forgejo -"
    "d /persist/backups/continuwuity 0750 root continuwuity -"
    "d /persist/backups/continuwuity/database 0750 continuwuity continuwuity -"
    "d /persist/backups/continuwuity/weekly 0750 root root -"
    "d /persist/backups/restic 0750 usu users -"
    "d /persist/backups/restic/shade 0750 usu users -"
    "d /persist/backups/restic/offsite 0750 root root -"
    "d /persist/backups/vaultwarden 0770 vaultwarden vaultwarden -"
    "d /var/lib/prometheus-node-exporter-textfiles 0755 root root -"
  ];
}
