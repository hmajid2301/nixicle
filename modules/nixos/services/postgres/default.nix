{
  config,
  lib,
  pkgs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.postgresql;
in
{
  options.services.nixicle.postgresql = {
    enable = mkEnableOption "Enable postgresql";
    initialScript = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Initial script to run on PostgreSQL server startup";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.postgres_terraform_password = mkDefault {
      sopsFile = ../secrets.yaml;
    };

    sops.templates."init.sql" = {
      content = ''
        CREATE USER terraform WITH PASSWORD '${config.sops.placeholder.postgres_terraform_password}';
        CREATE DATABASE terraform;
        GRANT ALL PRIVILEGES ON DATABASE terraform TO terraform;
        ALTER DATABASE terraform OWNER TO terraform;
        \c terraform;
        GRANT ALL ON SCHEMA public TO terraform;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO terraform;
      '';
      owner = "postgres";
    };

    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        authentication = pkgs.lib.mkOverride 10 ''
          #...
          #type database DBuser origin-address auth-method
          local all       all     trust
          # ipv4
          host  all      all     127.0.0.1/32   trust
          # ipv6
          host all       all     ::1/128        trust
        '';
        initialScript =
          if cfg.initialScript != null then cfg.initialScript else config.sops.templates."init.sql".path;
      };

      postgresqlBackup = {
        enable = true;
        backupAll = true;
        startAt = "*-*-* 10:00:00";
      };

      traefik = {
        dynamicConfigOptions = {
          tcp = {
            services = {
              postgres = {
                loadBalancer = {
                  servers = [
                    {
                      address = "127.0.0.1:5432";
                    }
                  ];
                };
              };
            };

            routers = {
              postgres = {
                entryPoints = [ "postgres" ];
                rule = "HostSNI(`*`)";
                service = "postgres";
              };
            };
          };
        };
      };
    };
  };
}
