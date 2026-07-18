{ ... }:
{
  den.aspects.atticd = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/private/atticd";
        user = "atticd";
        group = "atticd";
        mode = "0750";
        defaultPerms.mode = "0700";
      }
    ];
    nixos =
      {
        config,
        secrets,
        lib,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        sops.secrets.attic = { };
        services.atticd = {
          enable = true;
          environmentFile = secretPaths.attic;
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
              rule = "Host(`attic.haseebmajid.dev`)";
              service = "attic";
              middlewares = [ "attic-timeout" ];
              tls = { };
            };
          };
        };

      };
  };
}
