_: {
  den = {
    default.nixos =
      { lib, ... }:
      {
        options.system.backup.objects = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                exclude = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
                initialize = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
                pruneOpts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "--keep-daily 7"
                    "--keep-weekly 4"
                    "--keep-monthly 3"
                  ];
                };
                checkOpts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                timerConfig = lib.mkOption {
                  type = with lib.types; nullOr (attrsOf anything);
                  default = {
                    OnCalendar = "daily";
                    RandomizedDelaySec = "1h";
                    Persistent = true;
                  };
                };
                backupPrepareCommand = lib.mkOption {
                  type = with lib.types; nullOr lines;
                  default = null;
                };
                backupCleanupCommand = lib.mkOption {
                  type = with lib.types; nullOr lines;
                  default = null;
                };
              };
            }
          );
        };
      };

    aspects.backup-restic = {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          backupObjects = config.system.backup.objects;
          resticWrapped = pkgs.writeShellScriptBin "restic" ''
            exec ${pkgs.util-linux}/bin/flock /run/restic-backups-global.lock \
              ${pkgs.restic}/bin/restic "$@"
          '';
        in
        {
          sops = {
            secrets = {
              restic_password = { };
              backblaze_env = { };
              restic_repository = { };
            };
          };

          services.restic.backups = lib.mapAttrs (_name: backup: {
            inherit (backup)
              paths
              exclude
              user
              initialize
              pruneOpts
              timerConfig
              backupPrepareCommand
              backupCleanupCommand
              ;
            runCheck = backup.checkOpts != [ ];
            inherit (backup) checkOpts;
            package = resticWrapped;
            passwordFile = config.sops.secrets.restic_password.path;
            environmentFile = config.sops.secrets.backblaze_env.path;
            repositoryFile = config.sops.secrets.restic_repository.path;
          }) backupObjects;

          systemd.services = lib.mapAttrs' (
            name: _backup:
            lib.nameValuePair "restic-backups-${name}" {
              path = [ pkgs.systemd ];
            }
          ) backupObjects;
        };
    };
  };
}
