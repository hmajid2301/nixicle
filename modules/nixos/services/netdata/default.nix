{
  config,
  lib,
  ...
}:
with lib;
 let
  cfg = config.services.nixicle.netdata;
in {
  options.services.nixicle.netdata = {
    enable = mkEnableOption "Enable the netdata service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.netdata = {
        enable = true;
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "netdata";
        port = 19999;
      };
    }
  ]);
}
