{ ... }:
{
  den.aspects.postgresql = {
    includes = [ ];
    persist.directories = [
      "/var/lib/postgresql"
      "/var/backup/postgresql"
    ];
    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        sops.secrets.postgres_terraform_password = {
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

        systemd.targets.postgresql-ready = {
          description = "PostgreSQL is ready";
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
        };

        services = {
          postgresql = {
            enable = true;
            package = pkgs.postgresql_18;
            authentication = pkgs.lib.mkOverride 10 ''
              #type database DBuser origin-address auth-method
              local all       all                     peer
              host  all       all     127.0.0.1/32   scram-sha-256
              host  all       all     ::1/128        scram-sha-256
            '';
            initialScript = config.sops.templates."init.sql".path;
          };

          postgresqlBackup = {
            enable = true;
            backupAll = true;
            startAt = "*-*-* 10:00:00";
          };
        };

      };
  };
}
