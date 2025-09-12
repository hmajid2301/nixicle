{
  config,
  lib,
  pkgs,
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
    terraformUser = {
      enable = mkEnableOption "Create terraform user and database";
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing terraform user password";
      };
    };
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_16_jit;
        extensions = ps: with ps; [ pgvecto-rs ];
        authentication = pkgs.lib.mkOverride 10 ''
          #...
          #type database DBuser origin-address auth-method
          local all       all     trust
          # ipv4
          host  all      all     127.0.0.1/32   trust
          # ipv6
          host all       all     ::1/128        trust
        '';
        settings = {
          shared_preload_libraries = [ "vectors.so" ];
          search_path = "\"$user\", public, vectors";
        };
      }
      // (lib.optionalAttrs (cfg.initialScript != null) {
        initialScript = cfg.initialScript;
      })
      // (lib.optionalAttrs cfg.terraformUser.enable {
        initialScript = if cfg.initialScript != null then cfg.initialScript else
          (pkgs.writeText "init-terraform-db.sql" ''
            CREATE USER terraform WITH PASSWORD '${builtins.readFile cfg.terraformUser.passwordFile}';
            CREATE DATABASE terraform;
            GRANT ALL PRIVILEGES ON DATABASE terraform TO terraform;
            ALTER DATABASE terraform OWNER TO terraform;
            \c terraform;
            GRANT ALL ON SCHEMA public TO terraform;
            GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO terraform;
          '');
      });
    }
    // (if cfg.initialScript != null then { initialScript = cfg.initialScript; } else { });

    postgresqlBackup = {
      enable = true;
      # location = "/mnt/share/postgresql";
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
}
