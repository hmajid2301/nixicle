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

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        2342
      ];
    };

    sops.secrets.photoprism_admin_password = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      photoprism = {
        enable = true;
        originalsPath = "/mnt/share/photoprism";
        passwordFile = config.sops.secrets.photoprism_admin_password.path;
        settings = {
          PHOTOPRISM_GID = "989";
        };
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.photos.loadBalancer.servers = [
              {
                url = "http://localhost:2342";
              }
            ];

            routers = {
              photos = {
                entryPoints = ["websecure"];
                rule = "Host(`photos.homelab.haseebmajid.dev`)";
                service = "photos";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
