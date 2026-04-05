{ den, ... }:
{
  den.aspects.traefik = {
    nixos = { config, lib, ... }: {
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      sops.secrets.cloudflare_api_key.sopsFile = ../../../hosts/framebox/secrets.yaml;

      systemd.services.traefik = {
        environment.CF_API_EMAIL = "hello@haseebmajid.dev";
        serviceConfig.EnvironmentFile = config.sops.secrets.cloudflare_api_key.path;
      };

      services.tailscale.permitCertUid = "traefik";

      services.traefik = {
        enable = true;
        staticConfigOptions = {
          metrics.prometheus = { };
          tracing = { };
          api.dashboard = true;
          certificatesResolvers = {
            tailscale.tailscale = { };
            letsencrypt.acme = {
              email = "hello@haseebmajid.dev";
              storage = "/var/lib/traefik/cert.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [ "1.1.1.1" ];
              };
            };
          };
          entryPoints = {
            redis.address = "0.0.0.0:6381";
            valkey.address = "0.0.0.0:6382";
            postgres.address = "0.0.0.0:5433";
            web = {
              address = "0.0.0.0:80";
              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
                permanent = true;
              };
            };
            websecure = {
              address = "0.0.0.0:443";
              http.tls = {
                certResolver = "letsencrypt";
                domains = [
                  { main = "homelab.haseebmajid.dev"; sans = [ "*.homelab.haseebmajid.dev" ]; }
                  { main = "port8082.homelab.haseebmajid.dev"; }
                  { main = "haseebmajid.dev"; sans = [ "*.haseebmajid.dev" ]; }
                  { main = "banterbus.games"; sans = [ "*.dev.banterbus.games" ]; }
                ];
              };
              transport.respondingTimeouts = {
                readTimeout = "10m";
                writeTimeout = "10m";
                idleTimeout = "10m";
              };
            };
          };
        };
      };

      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [ "/var/lib/traefik" ];
    };
  };
}
