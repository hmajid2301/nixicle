{ ... }:
{
  disko.devices = {
    disk = {
      # Boot disk only. Do not place any TrueNAS/ZFS data-pool disks in this file.
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE_ME_BOOT_DISK";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
