{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.services.nixicle.minio;
in
{
  options.services.nixicle.minio = {
    enable = mkEnableOption "Enable the minio";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.minio = {
        enable = true;
        listenAddress = ":9055";
        consoleAddress = ":9056";
        dataDir = [ "/mnt/n1/minio" ];
      };
    }

    # Traefik reverse proxy configuration - MinIO API
    {
      services.traefik.dynamicConfigOptions.http = mkMerge [
        (lib.nixicle.mkTraefikService {
          name = "minio";
          port = 9055;
        })

        # Traefik reverse proxy configuration - MinIO Console
        (lib.nixicle.mkTraefikService {
          name = "console-minio";
          port = 9056;
          subdomain = "console.minio";
        })
      ];
    }
  ]);
}
