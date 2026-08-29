_: {
  den.aspects.navidrome = {
    nixos =
      { lib, ... }:
      {
        services = {
          navidrome = {
            enable = true;
            group = "media";
            settings = {
              MusicFolder = "/mnt/n1/media/Music";
              ND_REVERSEPROXYUSERHEADER = "X-Forwarded-Preferred-Username";
              ND_REVERSEPROXYWHITELIST = "0.0.0.0/0";
            };
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
            name = "navidrome";
            port = 4533;
            domain = "haseebmajid.dev";
          };

        };
      };
  };
}
