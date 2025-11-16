{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.stirling-pdf;
in {
  options.services.nixicle.stirling-pdf = {
    enable = mkEnableOption "Enable stirling pdf service";
  };

  # TODO: need a way to configure the settings file
  config = mkIf cfg.enable (mkMerge [
    {
      services.stirling-pdf = {
        enable = true;
        environment = {
          SERVER_PORT = 8783;
          SECURITY_ENABLE_LOGIN = "true";
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "pdf";
        port = 8783;
      };
    }
  ]);
}
