{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      forwardAgent = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
    };
  };
}
