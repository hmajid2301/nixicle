{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.traefik;
in {
  options.services.nixicle.traefik = {
    enable = mkEnableOption "Enable traefik";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    services = {
      tailscale.permitCertUid = "traefik";

      traefik = {
        enable = true;
        staticConfigOptions = {
          certificatesResolvers = {
            tailscale.tailscale = {};
          };

          entryPoints.web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          entryPoints.websecure.address = ":443";
        };
      };
    };
  };
}
