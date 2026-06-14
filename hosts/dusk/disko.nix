{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              label = "esp";
              size = "4G";
              type = "EF00"; # efi fs
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=077"];
              };
            };
            swap = {
              label = "swap";
              size = "8G";
              content = {
                type = "luks";
                name = "cryptswap";
                content = {type = "swap";};
              };
            };
            root = {
              label = "root";
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                extraOpenArgs = ["--allow-discards"];
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "dusk" "-f"];
                  postCreateHook = ''
                    MNTPOINT=$(mktemp -d)
                    mount "/dev/mapper/cryptroot" "$MNTPOINT" -o subvol=/ && {
                      trap 'umount "$MNTPOINT" && rm -rf "$MNTPOINT"' EXIT
                      if btrfs subvolume show "$MNTPOINT/root" >/dev/null 2>&1; then
                        btrfs subvolume snapshot -r "$MNTPOINT/root" "$MNTPOINT/root-blank" ||
                          { echo "Snapshot failed!" >&2; exit 1; }
                      else
                        echo "Root subvolume missing!" >&2
                        exit 1
                      fi
                    } || {
                      echo "Mount failed!" >&2
                      rm -rf "$MNTPOINT"
                      exit 1
                    }
                  '';
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    "/var" = {
                      mountpoint = "/var";
                      mountOptions = ["subvol=var" "compress=zstd" "noatime"];
                    };
                    "/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = ["subvol=tmp" "compress=zstd" "noatime"];
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
