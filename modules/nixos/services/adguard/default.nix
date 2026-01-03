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
            upstream_dns = if config.services.nixicle.unbound.enable then [
              "127.0.0.1:5335"
            ] else [
              "https://dns.quad9.net/dns-query"
              "https://dns10.quad9.net/dns-query"
              "https://doh.mullvad.net/dns-query"
              "https://dns.njal.la/dns-query"
            ];
            bootstrap_dns = optionals (!config.services.nixicle.unbound.enable) [
              "9.9.9.9"
              "149.112.112.112"
              "2001:4860:4860::8888"
            ];
            fallback_dns = [
              "9.9.9.9"
              "149.112.112.112"
            ];
            cache_size = 67108864;
            cache_optimistic = true;
            enable_dnssec = true;
            edns_client_subnet = {
              enabled = true;
              use_custom = false;
            };
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
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
