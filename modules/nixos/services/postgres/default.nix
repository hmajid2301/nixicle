{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.postgresql;
in {
  options.services.nixicle.postgresql = {
    enable = mkEnableOption "Enable postgresql";
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_16_jit;
        extensions = ps: with ps; [pgvecto-rs];
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
          shared_preload_libraries = ["vectors.so"];
          search_path = "\"$user\", public, vectors";
        };
      };

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
                entryPoints = ["postgres"];
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
