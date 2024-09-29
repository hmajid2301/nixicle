{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.couchdb;
in {
  options.services.nixicle.couchdb = {
    enable = mkEnableOption "Enable CouchDB";
  };

  config = mkIf cfg.enable {
    services = {
      # couchdb = {
      #   enable = true;
      #   bindAddress = "0.0.0.0";
      #   adminUser = "admin";
      #   adminPass = "password";
      # };
      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              couchdb.loadBalancer.servers = [
                {
                  url = "http://localhost:5984";
                }
              ];
            };

            routers = {
              couchdb = {
                entryPoints = ["websecure"];
                rule = "Host(`couchdb.homelab.haseebmajid.dev`)";
                service = "couchdb";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
