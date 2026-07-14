{
  config,
  infraNetwork,
  lib,
  pkgs,
  ...
}: let
  domain = "git.${infraNetwork.domain}";
  forgejoState = config.services.forgejo.stateDir;
  forgejoCustom = pkgs.runCommand "forgejo-custom" {nativeBuildInputs = [pkgs.coreutils pkgs.imagemagick];} ''
    mkdir -p "$out/public/assets/img" "$out/public/assets/css" "$out/templates"

    magick ${../../../assets/forgejo/snowflake.jpg} -colorspace Gray -resize 240x240 -strip "$out/public/assets/img/mav-snowflake.png"
    magick ${../../../assets/forgejo/snowflake.jpg} -colorspace Gray -resize 180x180 -strip "$out/public/assets/img/apple-touch-icon.png"
    magick ${../../../assets/forgejo/snowflake.jpg} -colorspace Gray -resize 64x64 -strip "$out/public/assets/img/favicon.png"
    magick ${../../../assets/forgejo/snowflake.jpg} -colorspace Gray -resize 96x96 -strip "$out/public/assets/img/logo-embed.png"

    snowflake_png="$(${pkgs.coreutils}/bin/base64 -w0 "$out/public/assets/img/logo-embed.png")"
    cat > "$out/public/assets/img/logo.svg" <<EOF
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" width="96" height="96">
      <image href="data:image/png;base64,$snowflake_png" width="96" height="96" preserveAspectRatio="xMidYMid slice"/>
    </svg>
    EOF
    cp "$out/public/assets/img/logo.svg" "$out/public/assets/img/favicon.svg"

    cp ${../../../assets/forgejo/theme-marton.css} "$out/public/assets/css/theme-marton.css"
    cp ${../../../assets/forgejo/home.tmpl} "$out/templates/home.tmpl"
  '';
  installForgejoCustom = pkgs.writeShellScript "install-forgejo-custom" ''
    set -eu

    install -d -o forgejo -g forgejo -m 0755 \
      ${forgejoState}/custom/public/assets/img \
      ${forgejoState}/custom/public/assets/css \
      ${forgejoState}/custom/templates

    cp -f ${forgejoCustom}/public/assets/img/* ${forgejoState}/custom/public/assets/img/
    cp -f ${forgejoCustom}/public/assets/css/* ${forgejoState}/custom/public/assets/css/
    cp -f ${forgejoCustom}/templates/* ${forgejoState}/custom/templates/

    chown -R forgejo:forgejo ${forgejoState}/custom/public ${forgejoState}/custom/templates
  '';
  publishForgejoProfile = pkgs.writeShellScript "publish-forgejo-profile" ''
    set -eu

    ${pkgs.util-linux}/bin/runuser -u forgejo -- ${config.services.postgresql.package}/bin/psql \
      -d forgejo \
      -v ON_ERROR_STOP=1 \
      -c "update \"user\" set visibility = 0, theme = 'marton' where lower_name = 'usu';"
  '';
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
        APP_NAME = "Marton A. Varga";
        APP_SLOGAN = "Personal software forge";
        RUN_MODE = "prod";
      };
      actions.ENABLED = false;
      federation.ENABLED = false;
      mailer = {
        ENABLED = true;
        FROM = "Forgejo <martonaronvarga@gmail.com>";
        PROTOCOL = "smtps";
        SMTP_ADDR = "smtp.gmail.com";
        SMTP_PORT = 465;
        USER = "martonaronvarga@gmail.com";
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
        LANDING_PAGE = "home";
        START_SSH_SERVER = true;
      };
      "service.explore".REQUIRE_SIGNIN_VIEW = false;
      service = {
        DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
        DEFAULT_USER_VISIBILITY = "public";
        DISABLE_REGISTRATION = true;
        ENABLE_NOTIFY_MAIL = true;
        NO_REPLY_ADDRESS = "noreply.${domain}";
        SHOW_REGISTRATION_BUTTON = false;
      };
      session.COOKIE_SECURE = true;
      ui = {
        DEFAULT_SHOW_FULL_NAME = true;
        DEFAULT_THEME = "marton";
        SHOW_USER_EMAIL = false;
        THEMES = "forgejo-auto,forgejo-light,forgejo-dark,gitea-auto,gitea-light,gitea-dark,marton";
      };
    };
  };

  networking.firewall.interfaces.${infraNetwork.wireguard.interface}.allowedTCPPorts = [
    infraNetwork.dusk.ports.forgejo
    infraNetwork.dusk.ports.forgejoSsh
  ];

  systemd.services = {
    forgejo = {
      serviceConfig.ExecStartPre = lib.mkMerge [
        (lib.mkBefore [
          "+${pkgs.coreutils}/bin/chown -R forgejo:forgejo ${forgejoState}"
          "+${pkgs.coreutils}/bin/install -d -o forgejo -g forgejo -m 0750 ${forgejoState}/data/tmp/package-upload"
          "+${installForgejoCustom}"
        ])
        (lib.mkAfter [
          "+${publishForgejoProfile}"
        ])
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
