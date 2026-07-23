{
  inputs,
  ...
}:
let
  domain = "sure.haseebmajid.dev";
  port = 3099;
  subdomain = "sure";
in
{
  flake-file.inputs.sure-nix = {
    url = "github:nSimonFR/sure-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.sure = {
    includes = [ ];
    backup.sure.paths = [ "/var/lib/sure" ];
    persist.directories = [
      {
        directory = "/var/lib/sure";
        user = "sure";
        group = "sure";
        mode = "0750";
      }
    ];
    nixos =
      { config, pkgs, lib, ... }:
      let
        cfg = config.services.sure;
        waitForPocketId = ''
          echo "Waiting for Pocket ID OIDC discovery..."
          for i in $(seq 1 60); do
            if ${pkgs.curl}/bin/curl --fail --silent --show-error \
              https://id.haseebmajid.dev/.well-known/openid-configuration >/dev/null; then
              echo "Pocket ID OIDC discovery is ready"
              exit 0
            fi
            sleep 2
          done
          echo "Pocket ID OIDC discovery did not become ready in time" >&2
          exit 1
        '';

        # Build Sure with optional patches + inject declarative Pocket ID OIDC config
        surePackage = (pkgs.callPackage "${inputs.sure-nix}/package.nix" {
          patchFlags = {
            editable-linked-transaction-date = true;
          };
        }).overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            cat > config/auth.yml << 'YAMLEOF'
            providers:
              - id: "pocketid"
                strategy: "openid_connect"
                name: "Pocket ID"
                label: "Sign in with Pocket ID"
                issuer: "<%= ENV['OIDC_ISSUER'] %>"
                client_id: "<%= ENV['OIDC_CLIENT_ID'] %>"
                client_secret: "<%= ENV['OIDC_CLIENT_SECRET'] %>"
            YAMLEOF
          '';
        });
      in
      {
        imports = [ inputs.sure-nix.nixosModules.sure ];

        sops.secrets.sure_env = {
          owner = cfg.user;
          group = cfg.group;
          mode = "0400";
        };

        # TODO: PR this PostgreSQL setup back to sure-nix so the module handles
        # it natively (like `services.goroutinely.database.createLocally = true`),
        # making it a proper NixOS-style module.
        services.postgresql = {
          ensureDatabases = [ "sure" ];
          ensureUsers = [
            {
              name = "sure";
              ensureDBOwnership = true;
            }
          ];
        };

        systemd.services.sure-setup = {
          after = lib.mkAfter [
            "postgresql.service"
            "pocket-id.service"
          ];
        };

        systemd.services.sure-web = {
          after = lib.mkAfter [
            "postgresql.service"
            "pocket-id.service"
            "traefik.service"
            "network-online.target"
          ];
          wants = [
            "network-online.target"
            "pocket-id.service"
            "traefik.service"
          ];
          preStart = lib.mkBefore waitForPocketId;
        };

        systemd.services.sure-worker = {
          after = lib.mkAfter [
            "postgresql.service"
            "pocket-id.service"
          ];
        };

        services.sure = {
          enable = true;
          inherit port;
          package = surePackage;
          databaseUrl = "postgresql://sure@/sure?host=/run/postgresql";
          redisUrl = "redis://127.0.0.1:6379/0";
          environmentFile = config.sops.secrets.sure_env.path;
          settings = {
            AUTH_PROVIDERS_SOURCE = "yaml";
            OIDC_ISSUER = "https://id.haseebmajid.dev";
            OIDC_CLIENT_ID = "sure";
            RAILS_RELATIVE_URL_ROOT = "";
            RAILS_MAX_THREADS = "5";
            WEB_CONCURRENCY = "2";
            SECURITIES_PROVIDERS = "yahoo_finance";
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "sure";
          port = port;
          subdomain = subdomain;
          domain = "haseebmajid.dev";
        };
      };
  };
}
