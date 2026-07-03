{ ... }:
{
  den.aspects.gotify = {
    nixos =
      { lib, ... }:
      {
        services = {
          gotify = {
            enable = true;
            environment.GOTIFY_SERVER_PORT = "8051";
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "notify";
            port = 8051;
          };
        };
      };
  };
}
