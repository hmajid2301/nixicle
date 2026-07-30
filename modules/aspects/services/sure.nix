{
  inputs,
  ...
}:
let
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
      {
        config,
        lib,
        ...
      }:
      let
        cfg = config.services.sure;
      in
      {
        imports = [ inputs.sure-nix.nixosModules.sure ];

        sops.secrets.sure_env = {
          owner = cfg.user;
          group = cfg.group;
          mode = "0400";
        };

        # TODO: PR this PostgreSQL setup back to sure-nix so the module handles

        services = {

          # it natively (like `services.goroutinely.database.createLocally = true`),
          # making it a proper NixOS-style module.
          postgresql = {
            ensureDatabases = [ "sure" ];
            ensureUsers = [
              {
                name = "sure";
                ensureDBOwnership = true;
              }
            ];
          };

          sure = {
            enable = true;
            inherit port;
            databaseUrl = "postgresql:///sure?host=/run/postgresql&user=sure";
            redisUrl = "redis://127.0.0.1:6379/0";
            environmentFile = config.sops.secrets.sure_env.path;
            settings = {
              AUTH_PROVIDERS_SOURCE = "db";
              OIDC_ISSUER = "https://id.haseebmajid.dev";
              OIDC_CLIENT_ID = "sure";
              OIDC_BUTTON_LABEL = "Sign in with Pocket ID";
              RAILS_RELATIVE_URL_ROOT = "";
              RAILS_MAX_THREADS = "5";
              WEB_CONCURRENCY = "2";
              SECURITIES_PROVIDERS = "yahoo_finance";
            };
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "sure";
            domain = "haseebmajid.dev";
            inherit port subdomain;
          };
        };
      };
  };
}
