{ lib, config, pkgs, inputs, ...}: {
  imports = [
    ./fonts.nix 
    ./home-manager.nix
    ./xdg.nix
    ./direnv.nix
    ./hyprland.nix
    ./zsh.nix
  ];

  programs = {
    dconf.enable = true;
    gnupg.agent.enable = true;
  };

  environment.systemPackages = with pkgs; [ wget coreutils-full ];
  services.btrbk.instances.snapshot = {
    # snapshot on the start and the middle of every hour.
    onCalendar = "*:00,30";
    settings = {
      timestamp_format = "long-iso";
      preserve_day_of_week = "monday";
      preserve_hour_of_day = "23";
      # All snapshots are retained for at least 6 hours regardless of other policies.
      snapshot_preserve_min = "6h";
      volume."/" = {
        snapshot_dir = ".snapshots";
        subvolume."persist".snapshot_preserve = "48h 7d";
        subvolume."persist/home".snapshot_preserve = "48h 7d 4w";
      };
    };
  };

  services.btrfs.autoScrub.enable = true;
}
