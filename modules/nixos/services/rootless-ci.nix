{
  config,
  lib,
  ...
}: let
  cfg = config.local.rootlessCi;
  uid = toString cfg.uid;
  subuidEnd = toString (cfg.subordinateUidStart + 65535);
in {
  options.local.rootlessCi = {
    enable = lib.mkEnableOption "an isolated rootless CI container engine";
    user = lib.mkOption {
      type = lib.types.str;
      default = "gitea-runner";
    };
    uid = lib.mkOption {
      type = lib.types.ints.positive;
      default = 986;
    };
    subordinateUidStart = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300000;
    };
    home = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/gitea-runner";
    };
    images = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) uid home;
        group = cfg.user;
        createHome = true;
        homeMode = "0700";
        linger = true;
        subUidRanges = [
          {
            startUid = cfg.subordinateUidStart;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = cfg.subordinateUidStart;
            count = 65536;
          }
        ];
      };
      groups.${cfg.user} = {};
    };

    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = false;
      defaultNetwork.settings.dns_enabled = false;
    };

    systemd = {
      # The upstream module enables both sockets. CI needs only its user socket.
      sockets.podman.enable = false;
      services = {
        podman.enable = false;
        "user@${uid}" = {
          overrideStrategy = "asDropin";
          after = ["nftables.service"];
          requires = ["nftables.service"];
          bindsTo = ["nftables.service"];
        };
      };
      user = {
        sockets.podman.unitConfig.ConditionUser = cfg.user;
        services = {
          podman.unitConfig.ConditionUser = cfg.user;
          rootless-ci-images = {
            description = "Load declarative CI images into the rootless engine";
            unitConfig.ConditionUser = cfg.user;
            after = ["podman.socket"];
            requires = ["podman.socket"];
            restartTriggers = cfg.images;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = lib.concatMapStringsSep "\n" (image: "${config.virtualisation.podman.package}/bin/podman load --input ${image}") cfg.images;
          };
        };
      };
    };

    # Rootless networking emits host traffic as the engine UID. Include its
    # subordinate UIDs so host-network containers cannot bypass this policy.
    # This host OUTPUT hook is independent of Netavark's namespace rules.
    networking.nftables = {
      enable = true;
      tables.ci-egress = {
        family = "inet";
        content = ''
          chain restricted {
            ip daddr 127.0.0.53 udp dport 53 return
            ip daddr 127.0.0.53 tcp dport 53 return
            fib daddr type local reject
            ip daddr { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } reject
            meta nfproto ipv6 reject
          }
          chain output {
            type filter hook output priority -10; policy accept;
            meta skuid { ${uid}, ${toString cfg.subordinateUidStart}-${subuidEnd} } jump restricted
          }
        '';
      };
    };

    assertions = [
      {
        assertion = !(lib.elem "podman" config.users.users.${cfg.user}.extraGroups);
        message = "The CI account must not have access to a rootful Podman API.";
      }
    ];
  };
}
