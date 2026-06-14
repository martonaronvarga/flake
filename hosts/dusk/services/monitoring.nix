{
  pkgs,
  config,
  ...
}: {
  services = {
    # System metrics
    prometheus = {
      enable = false;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = ["systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev"];
          port = 9100;
        };
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1week
    '';
  };

  # Monitoring tools
  environment.systemPackages = with pkgs; [
    htop
    iotop
    iftop
    nethogs
  ];
}
