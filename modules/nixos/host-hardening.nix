{
  config,
  lib,
  pkgs,
  ...
}: let
  basicHardening = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
  };
in {
  boot.kernelParams = ["audit=1"];

  security = {
    apparmor = {
      enable = true;
      killUnconfinedConfinables = false;
    };
    auditd.enable = true;
    audit.enable = true;
  };

  services = {
    fstrim.enable = lib.mkDefault true;
    openssh.settings = {
      AllowUsers = ["usu"];
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
    smartd = {
      enable = lib.mkDefault true;
      autodetect = lib.mkDefault true;
    };
    btrfs.autoScrub = {
      enable = lib.mkDefault true;
      fileSystems = lib.mkDefault ["/"];
      interval = lib.mkDefault "weekly";
    };
  };

  systemd.services = lib.mkMerge [
    (lib.mkIf config.services.grafana.enable {
      grafana.serviceConfig = basicHardening;
    })
    (lib.mkIf config.services.nginx.enable {
      nginx.serviceConfig = basicHardening;
    })
    (lib.mkIf config.services.prometheus.enable {
      prometheus.serviceConfig = basicHardening;
    })
    (lib.mkIf config.services.prometheus.exporters.node.enable {
      prometheus-node-exporter.serviceConfig = basicHardening;
    })
    (lib.mkIf config.services.vaultwarden.enable {
      vaultwarden.serviceConfig = basicHardening;
    })
  ];

  environment.systemPackages = with pkgs; [
    apparmor-utils
    audit
    smartmontools
  ];
}
