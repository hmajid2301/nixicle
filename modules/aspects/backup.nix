{ den, lib, ... }:
{
  den.default.nixos =
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

  den.schema.host.includes = [
    (
      { class, aspect-chain }:
      den._.forward {
        each = lib.singleton true;
        fromClass = _: "backup";
        intoClass = _: "nixos";
        intoPath = _: [
          "system"
          "backup"
          "objects"
        ];
        fromAspect = _: lib.head aspect-chain;
        guard = { options, ... }: options ? system && options.system ? backup;
      }
    )
  ];

  den.aspects.backup-restic = {
    includes = [ ];
    nixos =
      {
        config,
        lib,
        pkgs,
        secrets,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
        backupObjects = config.system.backup.objects;
      in
      {
        sops.secrets.restic_password = { };
        sops.secrets.backblaze_env = { };
        sops.secrets.restic_repository = { };

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
          checkOpts = backup.checkOpts;
          passwordFile = secretPaths.restic_password;
          environmentFile = secretPaths.backblaze_env;
          repositoryFile = secretPaths.restic_repository;
        }) backupObjects;

        systemd.services = lib.mapAttrs' (name: _backup:
          lib.nameValuePair "restic-backups-${name}" {
            path = [ pkgs.systemd ];
          }
        ) backupObjects;
      };
  };
}
