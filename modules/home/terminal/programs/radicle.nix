{
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) network;
  startRadicle = pkgs.writeShellScript "start-radicle-node" ''
    set -eu
    RAD_PASSPHRASE="$(< /run/agenix/radicle-user-passphrase)"
    export RAD_PASSPHRASE
    exec ${lib.getExe' pkgs.radicle-node "radicle-node"} \
      --force \
      --listen ${network.shade.wireguard.address}:${toString network.shade.ports.radicleNode}
  '';
in {
  home.packages = with pkgs; [
    radicle-node
    radicle-tui
  ];

  systemd.user.services.radicle-node = {
    Unit = {
      Description = "Personal Radicle node";
      Documentation = "https://radicle.xyz/guides/user/";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
      ConditionPathExists = "%h/.radicle/keys/radicle";
      ConditionPathExistsGlob = "/run/agenix/radicle-user-passphrase";
    };
    Service = {
      ExecStart = startRadicle;
      Environment = [
        "RAD_HOME=%h/.radicle"
        "RUST_LOG=info"
      ];
      Restart = "on-failure";
      RestartSec = 10;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = ["%h/.radicle"];
    };
    Install.WantedBy = ["default.target"];
  };
}
