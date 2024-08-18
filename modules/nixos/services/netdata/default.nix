{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.netdata;
in {
  options.services.nixicle.netdata = {
    enable = mkEnableOption "Enable the netdata service";
  };

  config = mkIf cfg.enable {
    services = {
      netdata = {
        enable = true;
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              netdata.loadBalancer.servers = [
                {
                  url = "http://localhost:8384";
                }
              ];
            };

            routers = {
              netdata = {
                entryPoints = ["websecure"];
                rule = "Host(`netdata.bare.homelab.haseebmajid.dev`)";
                service = "netdata";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
