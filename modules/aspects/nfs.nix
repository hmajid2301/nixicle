{ ... }:
{
  den.aspects.nfs-truenas = {
    nixos = _: {
      services.rpcbind.enable = true;

      # /mnt/homelab: boot-time mount (no automount). Required by nixflix
      # services which mkdir -p on mount paths. Automount causes "Permission
      # denied" on mkdir and hangs on ls/stat when the mount isn't triggered.
      # nofail + restart ensures boot works even if NAS/Tailscale is slow.
      fileSystems."/mnt/homelab" = {
        device = "truenas:/mnt/main/main-encrypted";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.device-timeout=60s"
          "x-systemd.mount-timeout=60s"
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