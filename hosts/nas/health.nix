# Health, observability, and recovery detection for the NAS.
# Mirrors the TrueNAS monitoring stack: SMART daemon, ZFS Event Daemon.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  ports = builtins.concatStringsSep "," (
    map toString [
      config.services.prometheus.exporters.node.port
      config.services.prometheus.exporters.zfs.port
      config.services.prometheus.exporters.smartctl.port
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
      smartctl = {
        enable = true;
        openFirewall = false;
        maxInterval = "5m";
        extraFlags = [ "--smartctl.powermode-check=standby" ];
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

  systemd = {
    services = {
      nas-storage-metrics = {
        serviceConfig.Type = "oneshot";
        path = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        script = ''
          directory=/var/lib/prometheus-node-exporter-text-files
          temporary=$(mktemp "$directory/.nas-storage.XXXXXX")
          trap 'rm -f "$temporary"' EXIT
          mounted=0
          mountpoint -q /mnt/main/main-encrypted/homelab && mounted=1
          printf 'homelab_dataset_mounted{dataset="main/main-encrypted/homelab"} %s\n' "$mounted" > "$temporary"
          printf 'homelab_storage_last_collection_timestamp_seconds %s\n' "$(date +%s)" >> "$temporary"
          chmod 0644 "$temporary"
          mv "$temporary" "$directory/nas-storage.prom"
        '';
      };
      zfs-scrub = {
        serviceConfig = {
          Type = lib.mkForce "oneshot";
          TimeoutStartSec = "infinity";
        };
        postStart = ''
          directory=/var/lib/prometheus-node-exporter-text-files
          temporary=$(mktemp "$directory/.zfs-scrub.XXXXXX")
          trap 'rm -f "$temporary"' EXIT
          printf 'homelab_zfs_scrub_last_completed_timestamp_seconds{pool="main"} %s\n' "$(date +%s)" > "$temporary"
          chmod 0644 "$temporary"
          mv "$temporary" "$directory/zfs-scrub.prom"
        '';
      };
    };
    timers.nas-storage-metrics = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "5m";
      };
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
