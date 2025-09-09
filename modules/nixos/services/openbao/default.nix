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
      settings = {
        ui = true;
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
