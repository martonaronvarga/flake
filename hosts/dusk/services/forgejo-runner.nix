{
  config,
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) domain;
  runnerUuid = "65343739-3239-6238-3139-353237616130";
  runnerConfig = pkgs.writeText "forgejo-runner.yaml" (lib.generators.toYAML {} {
    log = {
      level = "info";
      job_level = "info";
    };
    runner = {
      capacity = 1;
      timeout = "30m";
      shutdown_timeout = "5m";
      fetch_interval = "5s";
    };
    cache.enabled = false;
    container = {
      network = "podman";
      enable_ipv6 = false;
      privileged = false;
      options = "--cpus=2 --memory=4g --pids-limit=1024 --dns=9.9.9.9 --dns=149.112.112.112";
      # Job stores and caches must not permit poisoning subsequent jobs.
      valid_volumes = [];
      docker_host = "-";
      force_pull = false;
      force_rebuild = false;
    };
    server.connections.dusk = {
      url = "https://git.${domain}";
      uuid = runnerUuid;
      token_url = "file:${config.age.secrets.forgejo-runner-token.path}";
      labels = ["nix-ci:docker://localhost/forgejo-nix-ci:latest"];
    };
  });
  ciImage = pkgs.dockerTools.buildLayeredImage {
    name = "localhost/forgejo-nix-ci";
    tag = "latest";
    contents = with pkgs; [
      alejandra
      bashInteractive
      cacert
      coreutils
      deadnix
      findutils
      gawk
      gitMinimal
      gnugrep
      gnused
      gzip
      nix
      nodejs
      statix
      gnutar
      which
    ];
    extraCommands = ''
      mkdir -p etc/nix etc/ssl/certs tmp
      chmod 1777 tmp
      cat > etc/nix/nix.conf <<'EOF'
      experimental-features = nix-command flakes
      sandbox = false
      build-users-group =
      max-jobs = 1
      cores = 2
      substituters = https://usu.cachix.org https://cache.nixos.org
      trusted-public-keys = usu.cachix.org-1:5jwkfmhQB89RUnXnSde4kN01awJGUqoBkqP0uRKPMFk= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      use-xdg-base-directories = true
      EOF
      ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-bundle.crt
      printf 'root:x:0:0:root:/root:/bin/bash\n' > etc/passwd
      printf 'root:x:0:\n' > etc/group
    '';
    config = {
      Cmd = ["/bin/bash"];
      Env = [
        "HOME=/root"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "PATH=/bin:/usr/bin"
      ];
      WorkingDir = "/workspace";
    };
  };
in {
  imports = [../../../modules/nixos/services/rootless-ci.nix];
  local.rootlessCi = {
    enable = true;
    images = [ciImage];
  };
  users.groups.forgejo-runner-secret.members = ["forgejo" "gitea-runner"];

  systemd.services = {
    forgejo-runner-register = {
      description = "Declaratively register the owner-scoped Forgejo runner";
      after = ["forgejo.service"];
      requires = ["forgejo.service"];
      before = ["gitea-runner-dusk.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "forgejo";
        Group = "forgejo";
        ExecStart = "${config.services.forgejo.package}/bin/forgejo --config /var/lib/forgejo/custom/conf/app.ini forgejo-cli actions register --name dusk-podman --scope usu --secret-file ${config.age.secrets.forgejo-runner-token.path} --labels nix-ci";
      };
    };

    gitea-runner-dusk = {
      description = "Forgejo Actions Runner";
      wantedBy = ["multi-user.target"];
      after = ["user@986.service" "forgejo-runner-register.service"];
      requires = ["user@986.service" "forgejo-runner-register.service"];
      bindsTo = ["user@986.service"];
      environment = {
        HOME = "/var/lib/gitea-runner";
        DOCKER_HOST = "unix:///run/user/986/podman/podman.sock";
        XDG_RUNTIME_DIR = "/run/user/986";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/986/bus";
      };
      serviceConfig = {
        User = "gitea-runner";
        Group = "gitea-runner";
        WorkingDirectory = "/var/lib/gitea-runner";
        ExecStartPre = "${pkgs.systemd}/bin/systemctl --user restart rootless-ci-images.service";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        # Expose this user's API/bus sockets through the otherwise hidden /run/user.
        BindPaths = ["/run/user/986"];
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/gitea-runner" "/run/user/986"];
        RestrictSUIDSGID = true;
        LockPersonality = true;
        ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${runnerConfig}";
        TimeoutStartSec = "10min";
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };
  };

  assertions = [
    {
      assertion = !lib.elem "nix-builder" config.users.users.usu.extraGroups;
      message = "The interactive user must not inherit the remote builder trust boundary.";
    }
  ];
}
