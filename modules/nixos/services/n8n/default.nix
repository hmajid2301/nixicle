{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.n8n;
in {
  options.services.nixicle.n8n = {
    enable = mkEnableOption "Enable n8n";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.n8n = {
        enable = true;
        openFirewall = true;
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "n8n";
        port = 5678;
      };
    }
  ]);
}
