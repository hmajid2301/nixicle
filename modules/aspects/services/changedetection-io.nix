let
  port = 5000;
in
{
  den.aspects.changedetection-io = {
    persist.directories = [
      {
        directory = "/var/lib/changedetection-io";
        user = "changedetection-io";
        group = "changedetection-io";
        mode = "0750";
      }
    ];

    nixos =
      { config, lib, ... }:
      {
        system.backup.objects.changedetection.paths = [ "/var/lib/changedetection-io" ];

        services = {
          changedetection-io = {
            enable = true;
            inherit port;
            behindProxy = true;
            playwrightSupport = true;
            baseURL = "https://changedetect.${config.nixicle.domains.root}";
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
            name = "changedetection-io";
            inherit port;
            subdomain = "changedetect";
            domain = config.nixicle.domains.root;
          };
        };
      };
  };
}
