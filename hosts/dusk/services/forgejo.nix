{
  config,
  infraNetwork,
  lib,
  pkgs,
  ...
}: let
  domain = "git.${infraNetwork.domain}";
  forgejoState = config.services.forgejo.stateDir;
in {
  services.forgejo = {
    enable = true;
    stateDir = "/var/lib/forgejo";
    database = {
      type = "postgres";
      user = "forgejo";
    };
    lfs = {
      enable = true;
      contentDir = "/var/lib/forgejo/data/lfs";
    };
    dump = {
      enable = true;
      backupDir = "/persist/backups/forgejo";
      interval = "04:15";
      type = "tar.zst";
      age = "4w";
    };
    secrets = {
      mailer.PASSWD = config.age.secrets.forgejo-mailer-password.path;
    };
    settings = {
      DEFAULT = {
        APP_NAME = "Marton A. Varga Git";
        APP_SLOGAN = "Personal software forge";
        RUN_MODE = "prod";
      };
      actions.ENABLED = false;
      federation.ENABLED = false;
      mailer = {
        ENABLED = true;
        FROM = "Forgejo <git@${infraNetwork.domain}>";
        PROTOCOL = "smtps";
        SMTP_ADDR = "smtp.gmail.com";
        SMTP_PORT = 465;
        USER = "git@${infraNetwork.domain}";
      };
      other = {
        SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
        SHOW_FOOTER_VERSION = false;
      };
      packages.ENABLED = false;
      repository = {
        DEFAULT_BRANCH = "main";
        DEFAULT_PRIVATE = "private";
        DISABLED_REPO_UNITS = "repo.packages,repo.actions";
        ENABLE_PUSH_CREATE_ORG = false;
        ENABLE_PUSH_CREATE_USER = true;
      };
      server = {
        BUILTIN_SSH_SERVER_USER = "git";
        DISABLE_SSH = false;
        DOMAIN = domain;
        ENABLE_GZIP = true;
        HTTP_ADDR = infraNetwork.dusk.wireguard.address;
        HTTP_PORT = infraNetwork.dusk.ports.forgejo;
        OFFLINE_MODE = true;
        ROOT_URL = "https://${domain}/";
        SSH_DOMAIN = domain;
        SSH_LISTEN_HOST = infraNetwork.dusk.wireguard.address;
        SSH_LISTEN_PORT = infraNetwork.dusk.ports.forgejoSsh;
        SSH_PORT = infraNetwork.dusk.ports.forgejoSsh;
        SSH_USER = "git";
        START_SSH_SERVER = true;
      };
      service = {
        DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
        DEFAULT_USER_VISIBILITY = "limited";
        DISABLE_REGISTRATION = true;
        ENABLE_NOTIFY_MAIL = true;
        NO_REPLY_ADDRESS = "noreply.${domain}";
        SHOW_REGISTRATION_BUTTON = false;
      };
      session.COOKIE_SECURE = true;
      ui = {
        DEFAULT_SHOW_FULL_NAME = true;
        DEFAULT_THEME = "forgejo-dark";
        SHOW_USER_EMAIL = false;
      };
    };
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.forgejo
    infraNetwork.dusk.ports.forgejoSsh
  ];

  systemd.services = {
    forgejo = {
      serviceConfig.ExecStartPre = lib.mkBefore [
        "+${pkgs.coreutils}/bin/chown -R forgejo:forgejo ${forgejoState}"
        "+${pkgs.coreutils}/bin/install -d -o forgejo -g forgejo -m 0750 ${forgejoState}/data/tmp/package-upload"
      ];
    };

    forgejo-secrets = {
      after = ["var-lib-forgejo.mount" "systemd-tmpfiles-resetup.service"];
      serviceConfig = {
        ExecStartPre = "+${pkgs.coreutils}/bin/install -d -o forgejo -g forgejo -m 0750 ${forgejoState}/custom/conf";
        ReadWritePaths = lib.mkForce [forgejoState];
      };
      wants = ["systemd-tmpfiles-resetup.service"];
    };
  };
}
