{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.adguard;
in {
  options.services.nixicle.adguard = {
    enable = mkEnableOption "Enable AdGuard Home";
  };

  config = mkIf cfg.enable {
    networking.firewall = lib.mkForce {
      enable = true;
      allowedUDPPorts = [
        53
      ];

      allowedTCPPorts = [
        53
      ];
    };

    services.adguardhome = {
      enable = true;
      openFirewall = true;
      allowDHCP = true;
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            adguardhome.loadBalancer.servers = [
              {
                url = "http://localhost:3000";
              }
            ];
          };

          routers = {
            adguardhome = {
              entryPoints = ["websecure"];
              rule = "Host(`adguard.bare.homelab.haseebmajid.dev`)";
              service = "adguardhome";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };
}
