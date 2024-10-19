{
  disko.devices = { device ? "/dev/nvme0n1", ... }: {
    disk = {
      nvme = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            esp = {
              label = "esp";
              start = "0";
              end = "4G";
              # EFI Filesystem
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              label = "swap";
              start = "4G";
              end = "24G";
              content = {
                type = "luks";
                name = "cryptswap";
                content = {
                  type = "swap";
                };
              };
            };
            root = {
              label = "root";
              start = "24G";
              end = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist/home" = {
                      mountpoint = "/persist/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/.snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
