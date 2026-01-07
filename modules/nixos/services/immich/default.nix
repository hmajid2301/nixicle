{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.services.nixicle.immich;
in
{
  options.services.nixicle.immich = with types; {
    enable = mkBoolOpt false "Enable the immich photo service";
    mediaLocation = mkOpt str "/mnt/homelab/homelab/immich" "Directory to store immich media files";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.users.immich.extraGroups = [ "media" "redis-main" ];

      systemd.services.immich-server = {
        serviceConfig = {
          BindPaths = mkIf (hasPrefix "/mnt/homelab" cfg.mediaLocation) [ "/mnt/homelab" ];
        };
        requires = optional (hasPrefix "/mnt/homelab" cfg.mediaLocation) "mnt-homelab.mount";
        after = optional (hasPrefix "/mnt/homelab" cfg.mediaLocation) "mnt-homelab.mount";
      };

      systemd.services.immich-machine-learning = {
        serviceConfig = {
          BindPaths = mkIf (hasPrefix "/mnt/homelab" cfg.mediaLocation) [ "/mnt/homelab" ];
        };
        requires = optional (hasPrefix "/mnt/homelab" cfg.mediaLocation) "mnt-homelab.mount";
        after = optional (hasPrefix "/mnt/homelab" cfg.mediaLocation) "mnt-homelab.mount";
      };

      services.immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = cfg.mediaLocation;
        database.enableVectors = false;
        database.enableVectorChord = true;
        redis.host = config.services.redis.servers.main.unixSocket;
      };

      environment.persistence."/persist" = mkIf config.system.impermanence.enable {
        directories = [
          {
            directory = "/var/lib/immich";
            user = "immich";
            group = "immich";
            mode = "0750";
          }
        ];
      };
    }
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "immich";
        port = 2283;
      };
    }
  ]);
}
