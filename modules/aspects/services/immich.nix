_:
let
  mediaLocation = "/mnt/homelab/homelab/immich";
in
{
  den.aspects.immich = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/immich";
        user = "immich";
        group = "immich";
        mode = "0750";
      }
    ];
    nixos =
      { config, lib, ... }:
      {
        sops.secrets = {
          "immich/client_id" = {
            owner = config.services.immich.user;
            group = config.services.immich.group;
            mode = "0400";
          };
          "immich/client_secret" = {
            owner = config.services.immich.user;
            group = config.services.immich.group;
            mode = "0400";
          };
        };

        users.users.immich.extraGroups = [
          "media"
          "redis-main"
        ];

        systemd.services.immich-server = {
          serviceConfig.BindPaths = [ "/mnt/homelab" ];
          requires = [
            "mnt-homelab.mount"
            "mnt-homelab-homelab.mount"
          ];
          after = [
            "mnt-homelab.mount"
            "mnt-homelab-homelab.mount"
          ];
        };

        systemd.services.immich-machine-learning = {
          serviceConfig.BindPaths = [ "/mnt/homelab" ];
          requires = [
            "mnt-homelab.mount"
            "mnt-homelab-homelab.mount"
          ];
          after = [
            "mnt-homelab.mount"
            "mnt-homelab-homelab.mount"
          ];
        };

        services.immich = {
          enable = true;
          host = "127.0.0.1";
          inherit mediaLocation;
          redis.host = config.services.redis.servers.main.unixSocket;
          settings = {
            library.watch.enabled = false;
            server.externalDomain = "https://immich.haseebmajid.dev";
            passwordLogin.enabled = false;
            oauth = {
              enabled = true;
              issuerUrl = "https://id.haseebmajid.dev";
              clientId._secret = config.sops.secrets."immich/client_id".path;
              clientSecret._secret = config.sops.secrets."immich/client_secret".path;
              scope = "openid email profile";
              tokenEndpointAuthMethod = "client_secret_post";
              buttonText = "Sign in with Pocket ID";
              autoRegister = true;
              autoLaunch = true;
            };
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "immich";
          port = 2283;
          subdomain = "immich";
          domain = "haseebmajid.dev";
        };

      };
  };
}
