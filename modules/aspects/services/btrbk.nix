{ den, ... }:
{
  den.aspects.btrbk = {
    nixos = { config, pkgs, lib, ... }: {
      sops.secrets.b2_access_key.sopsFile = ../../../hosts/framebox/secrets.yaml;
      sops.secrets.b2_secret_key.sopsFile = ../../../hosts/framebox/secrets.yaml;

      services.btrbk.instances.local = {
        onCalendar = "weekly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "0d 2w 6m";
          target_preserve_min = "no";
          target_preserve = "0d 2w 6m";
          volume = {
            "/persist" = {
              subvolume."." = {
                snapshot_dir = ".snapshots";
                target = "/mnt/truenas/backups/framebox/persist";
              };
            };
            "/home" = {
              subvolume."." = {
                snapshot_dir = ".snapshots";
                target = "/mnt/truenas/backups/framebox/home";
              };
            };
          };
        };
      };

      systemd.services.btrbk-b2-upload = {
        description = "Upload btrbk snapshots to Backblaze B2";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        script = ''
          set -euo pipefail
          export AWS_ACCESS_KEY_ID=$(cat ${config.sops.secrets.b2_access_key.path})
          export AWS_SECRET_ACCESS_KEY=$(cat ${config.sops.secrets.b2_secret_key.path})
          for path in /persist/.snapshots /home/.snapshots; do
            if [ -d "$path" ]; then
              echo "Syncing $path to B2..."
              ${pkgs.awscli2}/bin/aws s3 sync \
                --endpoint-url https://s3.us-west-004.backblazeb2.com \
                "$path" \
                "s3://Majiy00Homelab/${config.networking.hostName}/$(basename $path)/" \
                --storage-class GLACIER \
                --exclude "*.tmp" \
                --exclude "*/.config/gtk-*/*"
            fi
          done
          echo "B2 upload completed"
        '';
      };

      systemd.timers.btrbk-b2-upload = {
        description = "Timer for Backblaze B2 upload";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };

      environment.systemPackages = [ pkgs.btrbk ];

      systemd.tmpfiles.rules = [
        "d /home/.snapshots 0755 root root -"
        "d /persist/.snapshots 0755 root root -"
      ];
    };
  };
}
