{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.btrbk;
in
{
  options.services.nixicle.btrbk = {
    enable = mkEnableOption "Enable btrbk backups";

    instances = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            onCalendar = mkOption {
              type = types.str;
              default = "daily";
              description = "When to run the backup (systemd OnCalendar format)";
            };

            subvolumes = mkOption {
              type = types.attrsOf (
                types.submodule {
                  options = {
                    target = mkOption {
                      type = types.str;
                      description = "Target location for snapshots";
                    };

                    snapshot_dir = mkOption {
                      type = types.str;
                      default = ".snapshots";
                      description = "Directory name for snapshots within the subvolume";
                    };
                  };
                }
              );
              default = { };
              description = "Subvolumes to backup";
            };

            retention = {
              daily = mkOption {
                type = types.int;
                default = 7;
                description = "Number of daily snapshots to keep";
              };

              weekly = mkOption {
                type = types.int;
                default = 4;
                description = "Number of weekly snapshots to keep";
              };

              monthly = mkOption {
                type = types.int;
                default = 6;
                description = "Number of monthly snapshots to keep";
              };
            };
          };
        }
      );
      default = { };
      description = "Btrbk backup instances";
    };

    backblaze = {
      enable = mkEnableOption "Enable Backblaze B2 upload";

      bucket = mkOption {
        type = types.str;
        description = "Backblaze B2 bucket name";
      };

      endpoint = mkOption {
        type = types.str;
        default = "s3.us-west-004.backblazeb2.com";
        description = "Backblaze B2 endpoint";
      };

      paths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Paths to upload to B2 (typically snapshot directories)";
      };

      onCalendar = mkOption {
        type = types.str;
        default = "weekly";
        description = "When to upload to B2 (systemd OnCalendar format)";
      };
    };
  };

  config = mkIf cfg.enable {
    services.btrbk.instances = mapAttrs (
      name: instanceCfg:
      {
        onCalendar = instanceCfg.onCalendar;
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "${toString instanceCfg.retention.daily}d ${toString instanceCfg.retention.weekly}w ${toString instanceCfg.retention.monthly}m";
          target_preserve_min = "no";
          target_preserve = "${toString instanceCfg.retention.daily}d ${toString instanceCfg.retention.weekly}w ${toString instanceCfg.retention.monthly}m";

          volume = mapAttrs (
            subvol: subvolCfg: {
              subvolume = {
                "." = {
                  snapshot_dir = subvolCfg.snapshot_dir;
                  target = subvolCfg.target;
                };
              };
            }
          ) instanceCfg.subvolumes;
        };
      }
    ) cfg.instances;

    # Backblaze B2 upload service
    systemd.services.btrbk-b2-upload = mkIf cfg.backblaze.enable {
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

        ${concatMapStringsSep "\n" (path: ''
          if [ -d "${path}" ]; then
            echo "Syncing ${path} to B2..."
            ${pkgs.awscli2}/bin/aws s3 sync \
              --endpoint-url https://${cfg.backblaze.endpoint} \
              "${path}" \
              "s3://${cfg.backblaze.bucket}/${config.networking.hostName}/$(basename ${path})/" \
              --storage-class GLACIER \
              --exclude "*.tmp" \
              --exclude "*/.config/gtk-*/*"
          fi
        '') cfg.backblaze.paths}

        echo "B2 upload completed"
      '';
    };

    systemd.timers.btrbk-b2-upload = mkIf cfg.backblaze.enable {
      description = "Timer for Backblaze B2 upload";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.backblaze.onCalendar;
        Persistent = true;
      };
    };

    sops.secrets.b2_access_key = mkIf cfg.backblaze.enable { };

    sops.secrets.b2_secret_key = mkIf cfg.backblaze.enable { };

    environment.systemPackages = [ pkgs.btrbk ];

    systemd.tmpfiles.rules = [
      "d /home/.snapshots 0755 root root -"
      "d /persist/.snapshots 0755 root root -"
    ];
  };
}
