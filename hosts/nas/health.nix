# Health, observability, and recovery detection for the NAS.
# Mirrors the TrueNAS monitoring stack: SMART daemon, ZFS Event Daemon.
{ config, pkgs, ... }:
let
  ports = builtins.concatStringsSep "," (
    map toString [
      config.services.prometheus.exporters.node.port
      config.services.prometheus.exporters.zfs.port
    ]
  );
in
{
  services = {
    prometheus.exporters = {
      node = {
        enable = true;
        port = 3021;
        enabledCollectors = [ "systemd" ];
        openFirewall = false;
      };
      zfs = {
        enable = true;
        pools = [ "main" ];
        openFirewall = false;
        extraFlags = [
          "--no-collector.dataset-filesystem"
          "--no-collector.dataset-volume"
          "--properties.pool=allocated,free,health,size"
        ];
      };
    };

    # SMART monitoring for all local disks (matches TrueNAS DEVICESCAN policy).
    smartd = {
      enable = true;
      autodetect = true;
      defaults.monitored = "-a -o on -S on -n standby,q";
    };

    # ZFS Event Daemon for pool fault alerts. ZED is auto-enabled when
    # boot.zfs is enabled; we just configure its settings.
    zfs.zed.settings = {
      ZED_DEBUG_LOG = "/var/log/zed.debug.log";
      ZED_EMAIL_ADDR = "root";
      ZED_NOTIFY_VERBOSE = "1";
    };
  };

  networking.firewall.extraCommands = ''
    ip46tables -I nixos-fw 1 -p tcp -m multiport --dports ${ports} ! -i tailscale0 -j nixos-fw-refuse
    ip46tables -I nixos-fw 1 -p tcp -m multiport --dports ${ports} -i lo -j nixos-fw-accept
  '';

  # Live SSH dashboard (from daskladas/nasdots pattern)
  # `sudo nas-status` for live 5s-refresh view.
  environment.systemPackages = with pkgs; [
    smartmontools
    nvme-cli
    (writeShellScriptBin "nas-status" (builtins.readFile ./scripts/nas-status))
  ];
}
