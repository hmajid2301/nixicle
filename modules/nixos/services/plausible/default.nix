{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.plausible;
in {
  options.services.nixicle.plausible = {
    enable = mkEnableOption "Enable the plausible service";
  };

  config = mkIf cfg.enable {
    sops.secrets.plausible_admin_password = {
      sopsFile = ../secrets.yaml;
    };

    sops.secrets.plausible_secret_keybase_file = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      plausible = {
        enable = true;
        server = {
          baseUrl = "https://plausible.bare.homelab.haseebmajid.dev";
          port = 8455;
          secretKeybaseFile = config.sops.secrets.plausible_secret_keybase_file.path;
        };
        adminUser = {
          email = "hello@haseebmajid.dev";
          passwordFile = config.sops.secrets.plausible_admin_password.path;
          activate = true;
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              plausible.loadBalancer.servers = [
                {
                  url = "http://localhost:8455";
                }
              ];
            };

            routers = {
              plausible = {
                entryPoints = ["websecure"];
                rule = "Host(`plausible.bare.homelab.haseebmajid.dev`)";
                service = "plausible";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
