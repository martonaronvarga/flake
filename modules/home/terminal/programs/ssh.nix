_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ForwardAgent = false;
      ServerAliveInterval = 0;
      ServerAliveCountMax = 3;
    };
  };
}
