{
  lib,
  pkgs,
  ...
}: {
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
    };
    Service = {
      ExecStart = "${lib.getExe' pkgs.radicle-node "radicle-node"} --force --listen 127.0.0.1:8776";
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
