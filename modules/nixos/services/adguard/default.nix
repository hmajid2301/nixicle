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

  config = mkIf cfg.enable (mkMerge [
    {
      networking.firewall = {
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
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "adguardhome";
        port = 3000;
        subdomain = "adguard";
      };
    }
  ]);
}
