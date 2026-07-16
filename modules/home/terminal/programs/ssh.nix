{
  inventory,
  lib,
  pkgs,
  ...
}: let
  inherit (inventory) network;
in {
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
        HostName = network.gloam.publicIp;
        User = network.gloam.sshUser;
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      dusk = {
        HostName = network.dusk.wireguard.address;
        User = "usu";
        ProxyJump = "gloam";
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
