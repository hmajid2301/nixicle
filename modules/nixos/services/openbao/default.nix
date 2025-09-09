{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.openbao;
in
{
  options.services.nixicle.openbao = with types; {
    enable = mkBoolOpt false "Whether or not to enable OpenBao";
  };

  config = mkIf cfg.enable {
    services.openbao = {
      enable = true;
      address = "0.0.0.0:8200";
      storageBackend = "file";
      storagePath = "/var/lib/openbao";
      settings = {
        ui = true;
        api_addr = "http://0.0.0.0:8200";
        cluster_addr = "http://0.0.0.0:8201";
      };
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            openbao.loadBalancer.servers = [
              {
                url = "http://localhost:8200";
              }
            ];
          };

          routers = {
            openbao = {
              entryPoints = [ "websecure" ];
              rule = "Host(`openbao.homelab.haseebmajid.dev`)";
              service = "openbao";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };
}

