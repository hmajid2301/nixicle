{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.authentik;
in {
  options.services.nixicle.authentik = {
    enable = mkEnableOption "Enable the authentik auth service";
  };

  config = mkIf cfg.enable {
    sops.secrets.authenik_env = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      authentik = {
        enable = true;
        environmentFile = config.sops.secrets.authenik_env.path;
        settings = {
          # TODO: fill this settings
          email = {
            host = "smtp.example.com";
            port = 587;
            username = "authentik@example.com";
            use_tls = true;
            use_ssl = false;
            from = "auth@haseebmajid.dev";
          };
          disable_startup_analytics = true;
          avatars = "initials";
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              auth.loadBalancer.servers = [
                {
                  url = "http://localhost:9000";
                }
              ];
            };

            routers = {
              auth = {
                entryPoints = ["websecure"];
                rule = "Host(`auth.bare.homelab.haseebmajid.dev`)";
                service = "auth";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
