{
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) network;
in {
  xdg.configFile."ssh/known_hosts-forgejo".text = ''
    [${network.dusk.wireguard.address}]:${toString network.dusk.ports.forgejoSsh} ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT74l4KR4hbj4NwlpLlDGOXIgjAJfxu56cse/pl3WCG+ikyVryWNV7pzTbEXmUHVwe+92c3o0KKPGrjnCvANC8yWhLszdIynfooI9XEY6tLWS6ZqEEWjArbYLgdZcUL/Df1zi/+rPYWxpMFw7Ec5ciJpxaPaCNlm2wCJyDh+oLegJ7H2V8YzPn2b/qUHd5OlEO7/eB5M0YaFsOR3n1zUDczDbfNGaTvUHXrFbwaVAKxdfcf74SDIJGi6O9zrBadwIldLVyeC2ytjI7Bnm9Rv9VQwUBijbW5ydjT5KT9GRDsl2j5ILO0NnYa7+YIsT/gELelNCnrS2Rsunx8Fp4H2FP7ReUv0P1+vreh0BYQL1oGQ8htoK/44xUlA6O9eu7vj/k6GfwQO9zybADqLf6sN/uJsCG/Pju1LbYXuyu3JWSeUQui6Tvb4eupptBF5fgwaythpOGRGCKi0Rd5fUPMoEWo9zJAE5HdNuYz1ny6UjbotQyVO2AAwWdZ9KTOsSXt8ovcOkOtaXRlG6n7UziS3FI2N7PJZcftn9kReqswYrNpXdpr9mMcJZMwREoTZR8jdENv2heWH4+xdEuroeQ8qRjcpCaM4L17mbgNktuAM1yGnKpsG+bnKydRG5FztIF3fLzbgz51DYh1U4/Srk6raTN3ioPQLzda85K4TTu1XKfMQ==
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%C";
        ControlPersist = "10m";
      };

      "atlasz eltehpc" = {
        HostName = "atlasz.elte.hu";
        User = "usumusu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      github = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      gloam = {
        HostName = network.gloam.wireguard.address;
        User = network.gloam.sshUser;
        Port = 22;
        ProxyJump = "dusk";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      dusk = {
        HostName = network.dusk.wireguard.address;
        User = "usu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      dusk-wg = {
        HostName = network.dusk.wireguard.address;
        User = "usu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      dusk-local = {
        HostName = "dusk.local";
        User = "usu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      forgejo = {
        HostName = network.dusk.wireguard.address;
        User = "forgejo";
        Port = network.dusk.ports.forgejoSsh;
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        UserKnownHostsFile = "~/.config/ssh/known_hosts-forgejo";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      oracle = {
        HostName = "vps.example.com";
        User = "todo";
        IdentityFile = "~/.ssh/oracle";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };

  home.activation.materializeSshConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_path="$HOME/.ssh/config"
    if [ -L "$config_path" ]; then
      target="$(${pkgs.coreutils}/bin/readlink -f "$config_path")"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$config_path"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$target" "$config_path"
    fi
  '';
}
