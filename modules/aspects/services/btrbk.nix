{ ... }:
{
  den.aspects.btrbk = {
    nixos =
      {
        config,
        pkgs,
        lib,
        secrets,
        ...
      }:
      let
        rsyncExcludes = [
          "*.sock"
          "*.fifo"
          ".backingFsBlockDev*"
          "Games"
          ".steam"
          ".lmstudio"
          ".cache"
          ".local/share/Steam"
          "~/.config/gtk/"
          "*.vdi"
          "*.qcow2"
          "*.iso"
          "node_modules"
          ".npm"
          ".cargo/registry"
        ];
        rsyncExcludeArgs = lib.concatStringsSep " " (map (p: "--exclude='${p}'") rsyncExcludes);
      in
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        sops.secrets.b2_access_key = { };
        sops.secrets.b2_secret_key = { };
        services.btrbk.instances.local = {
          onCalendar = "weekly";
          settings = {
            timestamp_format = "long";
            snapshot_preserve_min = "2d";
            snapshot_preserve = "0d 2w 6m";
            volume = {
              "/persist" = {
                subvolume."." = {
                  snapshot_dir = ".snapshots";
                };
              };
              "/home" = {
                subvolume."." = {
                  snapshot_dir = ".snapshots";
                };
              };
            };
          };
        };

        systemd = {
          services.btrbk-truenas-rsync = {
            description = "Rsync btrbk snapshots to TrueNAS";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
            };
            script = ''
              set -euo pipefail
              for path in /persist/.snapshots /home/.snapshots; do
                if [ -d "$path" ]; then
                  echo "Syncing $path to TrueNAS..."
                  ${pkgs.rsync}/bin/rsync -rlptD --no-o --no-g --delete \
                    ${rsyncExcludeArgs} \
                    "$path/" \
                    "/mnt/truenas/backups/${config.networking.hostName}/$(basename $path)/"
                fi
              done
              echo "TrueNAS rsync completed"
            '';
          };

          timers.btrbk-truenas-rsync = {
            description = "Timer for TrueNAS rsync backup";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "weekly";
              Persistent = true;
            };
          };

          services.btrbk-b2-upload = {
            description = "Upload btrbk snapshots to Backblaze B2";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
            };
            script = ''
              set -euo pipefail
              export AWS_ACCESS_KEY_ID=$(cat ${secretPaths.b2_access_key})
              export AWS_SECRET_ACCESS_KEY=$(cat ${secretPaths.b2_secret_key})
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

          timers.btrbk-b2-upload = {
            description = "Timer for Backblaze B2 upload";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "weekly";
              Persistent = true;
            };
          };

          tmpfiles.rules = [
            "d /home/.snapshots 0755 root root -"
            "d /persist/.snapshots 0755 root root -"
          ];
        };

        environment.systemPackages = [ pkgs.btrbk ];
      };
  };
}
