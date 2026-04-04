{ den, ... }:
{
  den.aspects.nfs-truenas = {
    nixos = { ... }: {
      services.rpcbind.enable = true;

      fileSystems."/mnt/homelab" = {
        device = "truenas:/mnt/main/main-encrypted";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "x-systemd.requires=tailscaled.service"
          "x-systemd.after=tailscaled.service"
        ];
      };

      fileSystems."/mnt/truenas" = {
        device = "truenas:/mnt/main/main";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "x-systemd.requires=tailscaled.service"
          "x-systemd.after=tailscaled.service"
        ];
      };
    };
  };
}
