{ ... }:
{
  den.aspects.uptime-kuma = {
    persist.directories = [ "/var/lib/uptime-kuma" ];

    nixos =
      { lib, ... }:
      {
        services = {
          uptime-kuma = {
            enable = true;
            settings = {
              HOST = "0.0.0.0";
              PORT = "4000";
            };
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
            name = "uptime-kuma";
            port = 4000;
            subdomain = "uptime";
          };
        };
      };
  };
}
