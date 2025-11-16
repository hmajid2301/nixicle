{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.syncthing;
in {
  options.services.nixicle.syncthing = {
    enable = mkEnableOption "Enable the syncthing service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        # dataDir = "/mnt/share/syncthing";
        # group = "media";
        openDefaultPorts = true;
        relay = {
          enable = true;
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "syncthing";
        port = 8384;
      };
    }
  ]);
}
