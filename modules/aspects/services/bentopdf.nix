{ den, ... }:
{
  den.aspects.bentopdf = {
    nixos = { lib, ... }: {
      services.bentopdf = {
        enable = true;
        domain = "bentopdf.haseebmajid.dev";
        nginx = {
          enable = true;
          virtualHost = {
            listen = [ { addr = "127.0.0.1"; port = 3001; } ];
            serverAliases = [ "localhost" ];
          };
        };
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "bentopdf";
        port = 3001;
        subdomain = "bentopdf";
      };
    };
  };
}
