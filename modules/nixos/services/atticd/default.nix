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
              responseForwarding = {
                flushInterval = "100ms";
              };
              serversTransport = "attic-transport";
            };
          };

          serversTransports = {
            attic-transport = {
              forwardingTimeouts = {
                dialTimeout = "30s";
                responseHeaderTimeout = "10m";
                idleConnTimeout = "10m";
              };
              maxIdleConnsPerHost = 100;
            };
          };

          middlewares = {
            attic-timeout = {
              buffering = {
                maxRequestBodyBytes = 10737418240;
                memRequestBodyBytes = 1073741824;
              };
            };
          };

          routers = {
            attic = {
              entryPoints = [ "websecure" ];
              rule = "Host(`attic.homelab.haseebmajid.dev`)";
              service = "attic";
              middlewares = [ "attic-timeout" ];
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          "/var/lib/atticd"
        ];
      };
    };
  };
}
