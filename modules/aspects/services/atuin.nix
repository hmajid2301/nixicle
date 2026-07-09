{ ... }:
{
  den.aspects.atuin = {
    includes = [ ];
    persist.directories = [ "/var/lib/atuin" ];
    nixos =
      { lib, ... }:
      {
        services.atuin = {
          enable = true;
          openRegistration = true;
          maxHistoryLength = 99999999;
          port = 8890;
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "atuin";
          port = 8890;
          subdomain = "atuin";
          domain = "haseebmajid.dev";
        };
      };
  };
}
