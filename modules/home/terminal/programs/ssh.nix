_: {
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
        IdentityFile = "~/.ssh/atlasz";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      "dusk dusk.oraclevcn.com" = {
        HostName = "dusk.oraclevcn.com";
        User = "usu";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      oracle = {
        HostName = "vps.example.com";
        User = "ubuntu";
        IdentityFile = "~/.ssh/oracle";
        IdentitiesOnly = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };
    };
  };
}
