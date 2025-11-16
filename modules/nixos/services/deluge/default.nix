{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.deluge;
in {
  options.services.nixicle.deluge = {
    enable = mkEnableOption "Enable the deluge downloader";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.deluge = {
        enable = true;
        web.enable = true;
        group = "media";
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "deluge";
        port = 8112;
      };
    }
  ]);
}
