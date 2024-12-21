{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
                subvolumes = {
                  "/root" = {mountpoint = "/";};
                  "/home" = {mountpoint = "/home";};
                  "/nix" = {mountpoint = "/nix";};
                  "/var" = {mountpoint = "/var";};
                };
              };
            };
          };
        };
      };

      nas = {
        type = "btrfs";
        devices = [
          "/dev/sda"
          "/dev/sdb"
          "/dev/sdc"
          "/dev/sdd"
        ];
        content = {
          type = "btrfs";
          extraArgs = ["-d" "raid5"];
          mountpoint = "/storage";
          mountOptions = [
            "compress=zstd"
            "noatime"
          ];
          subvolumes = {
            "/data" = {
              mountpoint = "/storage/data";
            };
            "/media" = {
              mountpoint = "/storage/media";
            };
            "/backups" = {
              mountpoint = "/storage/backups";
            };
          };
        };
      };
    };
  };
}
