{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.photoprism;
in {
  options.services.nixicle.photoprism = {
    enable = mkEnableOption "Enable photo prism";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      networking.firewall = {
        allowedTCPPorts = [
          2342
        ];
      };

      sops.secrets.photoprism_admin_password = {
        sopsFile = ../secrets.yaml;
      };

      services.photoprism = {
        enable = true;
        originalsPath = "/mnt/share/photoprism";
        passwordFile = config.sops.secrets.photoprism_admin_password.path;
        settings = {
          PHOTOPRISM_GID = "989";
        };
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "photos";
        port = 2342;
      };
    }
  ]);
}
