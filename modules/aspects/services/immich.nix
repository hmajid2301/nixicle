{ den, lib, ... }:
let
  mediaLocation = "/mnt/homelab/homelab/immich";
in
{
  den.aspects.immich = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = "/var/lib/immich"; user = "immich"; group = "immich"; mode = "0750"; }
        ];
    nixos = { config, lib, ... }: {
      users.users.immich.extraGroups = [ "media" "redis-main" ];

      systemd.services.immich-server = {
        serviceConfig.BindPaths = [ "/mnt/homelab" ];
        requires = [ "mnt-homelab.mount" ];
        after = [ "mnt-homelab.mount" ];
      };

      systemd.services.immich-machine-learning = {
        serviceConfig.BindPaths = [ "/mnt/homelab" ];
        requires = [ "mnt-homelab.mount" ];
        after = [ "mnt-homelab.mount" ];
      };

      services.immich = {
        enable = true;
        host = "0.0.0.0";
        inherit mediaLocation;
        redis.host = config.services.redis.servers.main.unixSocket;
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "immich";
        port = 2283;
      };

    };
  };
}
