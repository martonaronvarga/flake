{lib, ...}: {
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    memoryPercent = lib.mkDefault 50;
    priority = lib.mkDefault 100;
  };

  services.earlyoom = {
    enable = lib.mkDefault true;
    freeMemThreshold = lib.mkDefault 5;
    freeSwapThreshold = lib.mkDefault 10;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 100;
    "vm.page-cluster" = lib.mkDefault 0;
  };
}
