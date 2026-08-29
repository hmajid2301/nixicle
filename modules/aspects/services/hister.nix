_:
let
  port = 4433;
  domain = "haseebmajid.dev";
in
{
  den.aspects.hister = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/hister";
        user = "hister";
        group = "hister";
        mode = "0750";
      }
    ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        waitForPocketId = ''
          echo "Waiting for Pocket ID OIDC discovery..."
          for i in $(seq 1 60); do
            if ${pkgs.curl}/bin/curl --fail --silent --show-error \
              https://id.${domain}/.well-known/openid-configuration >/dev/null; then
              echo "Pocket ID OIDC discovery is ready"
              exit 0
            fi
            sleep 2
          done
          echo "Pocket ID OIDC discovery did not become ready in time" >&2
          exit 1
        '';
      in
      {
        sops.secrets.hister_oauth = {
          owner = "hister";
          group = "hister";
          mode = "0400";
        };

        systemd.services.hister = {
          after = [
            "network-online.target"
            "pocket-id.service"
            "postgresql.service"
          ];
          wants = [
            "network-online.target"
            "pocket-id.service"
          ];
          preStart = lib.mkBefore waitForPocketId;
        };

        services = {
          hister = {
            enable = true;
            user = "hister";
            group = "hister";
            dataDir = "/var/lib/hister";
            inherit port;
            openFirewall = false;
            environmentFile = config.sops.secrets.hister_oauth.path;
            settings = {
              app = {
                disable_previews = true;
                log_level = "info";
                user_handling = true;
              };

              server = {
                address = "127.0.0.1:${toString port}";
                base_url = "https://hister.${domain}";
                database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
                oauth_only = true;
                oauth.oidc = {
                  client_id = "hister";
                  configuration_url = "https://id.${domain}/.well-known/openid-configuration";
                };
              };
            };
          };

          postgresql = {
            ensureDatabases = [ "hister" ];
            ensureUsers = [
              {
                name = "hister";
                ensureDBOwnership = true;
              }
            ];
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "hister";
            inherit port domain;
          };
        };
      };
  };
}
