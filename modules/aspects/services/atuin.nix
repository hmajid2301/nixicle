_: {
  den.aspects.atuin = {
    persist.directories = [ "/var/lib/atuin" ];
    nixos =
      { config, lib, ... }:
      {
        services.atuin = {
          enable = true;
          openRegistration = false;
          maxHistoryLength = 99999999;
          port = 8890;
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "atuin";
          port = 8890;
          subdomain = "atuin";
          domain = config.nixicle.domains.root;
        };
      };
  };
}
