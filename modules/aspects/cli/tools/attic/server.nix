# The atticd server: runs the attic binary-cache daemon (behind traefik on
# attic.<root domain>) with Postgres + Backblaze B2 storage. Used by the
# host(s) that actually serve the cache; everyone else consumes it via
# `den.aspects.attic-cache`.
_: {
  den.aspects.attic-server = {
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
        lib,
        ...
      }:
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
            ensureDatabases = [ "atticd" ];
            ensureUsers = [
              {
                name = "atticd";
                ensureDBOwnership = true;
              }
            ];
          };

          atticd = {
            enable = true;
            environmentFile = config.sops.secrets.attic.path;
            settings = {
              listen = "127.0.0.1:8899";
              allowed-hosts = [ "attic.${config.nixicle.domains.root}" ];
              api-endpoint = "https://attic.${config.nixicle.domains.root}/";
              database.url = "postgresql:///atticd?host=/run/postgresql&user=atticd";
              chunking = {
                nar-size-threshold = 0;
                min-size = 16384;
                avg-size = 65536;
                max-size = 262144;
              };
              garbage-collection = {
                interval = "1 day";
                default-retention-period = "3 months";
              };
              storage = {
                type = "s3";
                endpoint = "http://vps:3900";
                region = "garage";
                bucket = "attic";
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
                responseHeaderTimeout = "1h";
                idleConnTimeout = "1h";
              };
              routers.attic = {
                entryPoints = [ "websecure" ];
                rule = "Host(`attic.${config.nixicle.domains.root}`)";
                service = "attic";
                tls.certResolver = "letsencrypt";
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
