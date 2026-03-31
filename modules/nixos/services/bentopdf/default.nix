{config, lib, ...}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.bentopdf;
in
{
  options.services.nixicle.bentopdf = with types; {
    enable = mkBoolOpt false "Enable bentopdf PDF toolkit service";
    domain = mkOpt types.str "bentopdf.haseebmajid.dev" "Domain for bentopdf";
    port = mkOpt types.int 3001 "Port for bentopdf (internal nginx)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        bentopdf = {
          enable = true;
          domain = cfg.domain;
          nginx = {
            enable = true;
            virtualHost = {
              listen = [
                {
                  addr = "127.0.0.1";
                  port = cfg.port;
                }
              ];
              serverAliases = [ "localhost" ];
            };
          };
        };
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "bentopdf";
        port = cfg.port;
        subdomain = "bentopdf";
      };
    }
  ]);
}