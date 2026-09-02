_: {
  den.aspects.redlib = {
    includes = [ ];

    nixos =
      { lib, ... }:
      {
        services.redlib = {
          enable = true;
          address = "127.0.0.1";
          port = 8929;
          settings = {
            REDLIB_DEFAULT_HIDE_NSFW = "on";
            REDLIB_ROBOTS_DISABLE_INDEXING = "on";
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
          name = "redlib";
          port = 8929;
          domain = "haseebmajid.dev";
        };
      };
  };
}
