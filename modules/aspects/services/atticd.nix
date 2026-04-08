{ den, lib, ... }:
{
  den.aspects.atticd = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = "/var/lib/private/atticd"; user = "atticd"; group = "atticd"; mode = "0750"; defaultPerms.mode = "0700"; }
        ];
    nixos = { config, lib, ... }: {
      sops.secrets.attic.sopsFile = ../../../hosts/framebox/secrets.yaml;

      services.atticd = {
        enable = true;
        environmentFile = config.sops.secrets.attic.path;
        settings.listen = "[::]:8899";
      };

      services.traefik.dynamicConfigOptions = {
        http = {
          services.attic.loadBalancer = {
            servers = [ { url = "http://localhost:8899"; } ];
            responseForwarding.flushInterval = "100ms";
            serversTransport = "attic-transport";
          };
          serversTransports.attic-transport.forwardingTimeouts = {
            dialTimeout = "30s";
            responseHeaderTimeout = "10m";
            idleConnTimeout = "10m";
          };
          middlewares.attic-timeout.buffering = {
            maxRequestBodyBytes = 21474836480;
            memRequestBodyBytes = 1073741824;
          };
          routers.attic = {
            entryPoints = [ "websecure" ];
            rule = "Host(`attic.homelab.haseebmajid.dev`)";
            service = "attic";
            middlewares = [ "attic-timeout" ];
            tls.certResolver = "letsencrypt";
          };
        };
      };

    };
  };
}
