{ ... }:
{
  den.aspects.atticd = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/atticd";
        user = "atticd";
        group = "atticd";
        mode = "0750";
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
        users.users.atticd = {
          isSystemUser = true;
          group = "atticd";
        };
        users.groups.atticd = { };

        sops.secrets.attic = {
          owner = "atticd";
          group = "atticd";
          mode = "0400";
        };

        services = {
          postgresql = {
            ensureDatabases = [ "attic" ];
            ensureUsers = [
              {
                name = "atticd";
                ensureDBOwnership = true;
              }
            ];
          };

          atticd = {
            enable = true;
            environmentFile = secretPaths.attic;
            settings = {
              listen = "[::]:8899";
              allowed-hosts = [ "attic.haseebmajid.dev" ];
              api-endpoint = "https://attic.haseebmajid.dev/";
              database.url = "postgresql:///attic?host=/run/postgresql";
              storage = {
                type = "s3";
                endpoint = "https://s3.us-west-004.backblazeb2.com";
                region = "us-west-004";
                bucket = "REPLACE_ME_BACKBLAZE_BUCKET";
              };
            };
          };

          traefik.dynamicConfigOptions = {
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

        systemd.services.atticd.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "atticd";
          Group = "atticd";
        };
      };
  };
}
