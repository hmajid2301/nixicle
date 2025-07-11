{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.atticd;
in
{
  options.services.nixicle.atticd = with types; {
    enable = mkBoolOpt false "Whether or not to enable attic daemon";
  };

  config = mkIf cfg.enable {

    sops.secrets.attic = {
      sopsFile = ../secrets.yaml;
    };

    services.atticd = {
      enable = true;
      environmentFile = config.sops.secrets."attic".path;
      settings = {
        listen = "[::]:8899";
      };
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            attic.loadBalancer = {
              servers = [
                {
                  url = "http://localhost:8899";
                }
              ];
              serversTransport = "attic-transport";
            };
          };

          serversTransports = {
            attic-transport = {
              forwardingTimeouts = {
                responseHeaderTimeout = "900s";
                idleTimeout = "900s";
                dialTimeout = "30s";
              };
            };
          };

          routers = {
            attic = {
              entryPoints = [ "websecure" ];
              rule = "Host(`attic.homelab.haseebmajid.dev`)";
              service = "attic";
              tls.certResolver = "letsencrypt";
              middlewares = [ "attic-headers" ];
            };
          };

          middlewares = {
            attic-headers = {
              headers = {
                requestHeaders = {
                  maxRequestBodyBytes = 21474836480;
                };
              };
            };
          };
        };
      };
    };
  };
}
