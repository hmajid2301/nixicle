{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.adguard;
in
{
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
        host = "0.0.0.0";
        port = 3000;
        settings = {
          dns = {
            upstream_dns = [
              "https://dns.quad9.net/dns-query"
              "https://dns10.quad9.net/dns-query"
              "https://dns.cloudflare.com/dns-query"
            ];
            bootstrap_dns = [
              "9.9.9.9"
              "149.112.112.112"
              "1.1.1.1"
            ];
            fallback_dns = [
              "9.9.9.9"
              "149.112.112.112"
            ];
          };
        };
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "adguardhome";
        port = 3000;
        subdomain = "adguard";
      };
    }

    {
      environment.persistence."/persist" = mkIf config.system.impermanence.enable {
        directories = [
          "/var/lib/private/AdGuardHome"
        ];
      };
    }
  ]);
}
