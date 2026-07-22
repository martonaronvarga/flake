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
    cache = {
      enabled = true;
      dir = "/var/lib/gitea-runner/cache";
    };
    container = {
      network = "podman";
      enable_ipv6 = false;
      privileged = false;
      options = "--cpus=2 --memory=4g --pids-limit=1024";
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
  users = {
    users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
      extraGroups = ["podman"];
    };
    groups = {
      gitea-runner = {};
      forgejo-runner-secret.members = ["forgejo" "gitea-runner"];
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      dns_enabled = true;
      subnets = [
        {
          subnet = "10.88.0.0/16";
          gateway = "10.88.0.1";
        }
      ];
    };
  };

  systemd.services = {
    forgejo-ci-image = {
      description = "Load the declarative Forgejo CI image into Podman";
      wantedBy = ["multi-user.target"];
      before = ["gitea-runner-dusk.service"];
      after = ["podman.socket"];
      requires = ["podman.socket"];
      restartTriggers = [ciImage];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman load --input ${ciImage}";
      };
    };

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
      after = ["forgejo-ci-image.service" "forgejo-runner-register.service"];
      requires = ["forgejo-ci-image.service" "forgejo-runner-register.service"];
      environment = {
        HOME = "/var/lib/gitea-runner";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
      };
      serviceConfig = {
        User = "gitea-runner";
        Group = "gitea-runner";
        WorkingDirectory = "/var/lib/gitea-runner";
        ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${runnerConfig}";
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };
  };

  # CI has public egress for fetching dependencies, but cannot reach Dusk,
  # WireGuard, or private LAN services from the Podman bridge.
  networking.firewall = {
    extraCommands = ''
      iptables -C FORWARD -s 10.88.0.0/16 -d 10.0.0.0/8 -j REJECT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 10.0.0.0/8 -j REJECT
      iptables -C FORWARD -s 10.88.0.0/16 -d 172.16.0.0/12 -j REJECT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 172.16.0.0/12 -j REJECT
      iptables -C FORWARD -s 10.88.0.0/16 -d 192.168.0.0/16 -j REJECT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 192.168.0.0/16 -j REJECT
      iptables -C FORWARD -s 10.88.0.0/16 -d 169.254.0.0/16 -j REJECT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 169.254.0.0/16 -j REJECT
      iptables -C FORWARD -s 10.88.0.0/16 -d 10.88.0.1/32 -p tcp --dport 53 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 10.88.0.1/32 -p tcp --dport 53 -j ACCEPT
      iptables -C FORWARD -s 10.88.0.0/16 -d 10.88.0.1/32 -p udp --dport 53 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -s 10.88.0.0/16 -d 10.88.0.1/32 -p udp --dport 53 -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D FORWARD -s 10.88.0.0/16 -d 10.0.0.0/8 -j REJECT 2>/dev/null || true
      iptables -D FORWARD -s 10.88.0.0/16 -d 172.16.0.0/12 -j REJECT 2>/dev/null || true
      iptables -D FORWARD -s 10.88.0.0/16 -d 192.168.0.0/16 -j REJECT 2>/dev/null || true
      iptables -D FORWARD -s 10.88.0.0/16 -d 169.254.0.0/16 -j REJECT 2>/dev/null || true
      iptables -D FORWARD -s 10.88.0.0/16 -d 10.88.0.1/32 -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -s 10.88.0.0/16 -d 10.88.0.1/32 -p udp --dport 53 -j ACCEPT 2>/dev/null || true
    '';
  };

  assertions = [
    {
      assertion = !lib.elem "nix-builder" config.users.users.usu.extraGroups;
      message = "The interactive user must not inherit the remote builder trust boundary.";
    }
  ];
}
