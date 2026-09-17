_:
let
  port = 4000;
in
{
  den.aspects.uptime-kuma = {
    persist.directories = [
      {
        directory = "/var/lib/uptime-kuma";
        user = "uptime-kuma";
        group = "uptime-kuma";
        mode = "0755";
      }
    ];

    nixos =
      { lib, ... }:
      {
        # Upstream module uses DynamicUser, which mounts a private tmpfs over
        # the persist bind mount (EBUSY). Run as a real user instead.
        users = {
          users.uptime-kuma = {
            isSystemUser = true;
            group = "uptime-kuma";
            home = "/var/lib/uptime-kuma";
          };
          groups.uptime-kuma = { };
        };

        systemd.services.uptime-kuma.serviceConfig.DynamicUser = lib.mkForce false;

        services = {
          uptime-kuma = {
            enable = true;
            settings = {
              HOST = "0.0.0.0";
              PORT = toString port;
            };
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
            name = "uptime-kuma";
            inherit port;
            subdomain = "uptime";
          };
        };
      };
  };
}
