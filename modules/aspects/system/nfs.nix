_: {
  # Client aspect: mounts the NAS NFS exports. The server host is now `nas`
  # (renamed from `truenas` during the TrueNAS -> NixOS migration). The NAS
  # exports both the plain and the (post-unlock) encrypted dataset.
  den.aspects.nfs-nas = {
    nixos = _: {
      services.rpcbind.enable = true;

      # /mnt/homelab: boot-time mount (no automount). Required by nixflix
      # services which mkdir -p on mount paths. Automount causes "Permission
      # denied" on mkdir and hangs on ls/stat when the mount isn't triggered.
      # nofail + restart ensures boot works even if NAS/Tailscale is slow.
      # /mnt/homelab/homelab: the `homelab` dataset under main-encrypted is a
      # separate ZFS dataset, so it must be exported AND mounted separately
      # (an unexported child dataset appears as an empty root-owned dir).
      fileSystems = {
        "/mnt/homelab/homelab" = {
          device = "nas:/mnt/main/main-encrypted/homelab";
          fsType = "nfs";
          options = [
            "nfsvers=4"
            "noatime"
            "nofail"
            "x-systemd.device-timeout=60s"
            "x-systemd.mount-timeout=60s"
            "x-systemd.requires=mnt-homelab.mount"
            "x-systemd.after=mnt-homelab.mount"
            "x-systemd.requires=tailscaled.service"
            "x-systemd.after=tailscaled.service"
          ];
        };

        "/mnt/homelab" = {
          device = "nas:/mnt/main/main-encrypted";
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

        "/mnt/nas" = {
          device = "nas:/mnt/main/main";
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
  };
}
