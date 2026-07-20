{ ... }:
{
  disko.devices = {
    disk = {
      # Boot disk only. Do not place any TrueNAS/ZFS data-pool disks in this file.
      boot = {
        type = "disk";
        # Observed old TrueNAS boot-pool disk during read-only recovery inspection.
        # Verify this still resolves to the intended 1TB WD boot/system disk before any destructive install.
        device = "/dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_21234L802961";
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
