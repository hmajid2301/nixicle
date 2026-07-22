# Health, observability, and recovery detection for the NAS.
# Mirrors the TrueNAS monitoring stack: SMART daemon, ZFS Event Daemon.
{ pkgs, ... }:
{
  # SMART monitoring for all local disks (matches TrueNAS DEVICESCAN policy).
  services.smartd = {
    enable = true;
    autodetect = true;
    defaults.monitored = "-a -o on -S on -n standby,q";
  };

  # ZFS Event Daemon for pool fault alerts. ZED is auto-enabled when
  # boot.zfs is enabled; we just configure its settings.
  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/var/log/zed.debug.log";
    ZED_EMAIL_ADDR = "root";
    ZED_NOTIFY_VERBOSE = "1";
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    nvme-cli
  ];
}