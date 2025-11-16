{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.couchdb;
in {
  options.services.nixicle.couchdb = {
    enable = mkEnableOption "Enable CouchDB";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.couchdb = {
        enable = true;
        adminUser = "admin";
        adminPass = "admin";
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "couchdb";
        port = 5984;
      };
    }
  ]);
}
