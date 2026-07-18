{
  inputs,
  ...
}:
{
  flake-file.inputs.goroutinely = {
    url = "gitlab:hmajid2301/goroutinely/fix-broken";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.goroutinely = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/goroutinely";
        user = "goroutinely";
        group = "goroutinely";
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
              https://id.haseebmajid.dev/.well-known/openid-configuration >/dev/null; then
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
        imports = [ inputs.goroutinely.nixosModules.default ];
        sops.secrets.goroutinely = {
          key = "goroutinely";
          owner = config.services.goroutinely.user;
          inherit (config.services.goroutinely) group;
          mode = "0400";
        };

        systemd.services.goroutinely = {
          after = [
            "network-online.target"
            "pocket-id.service"
            "traefik.service"
          ];
          wants = [
            "network-online.target"
            "pocket-id.service"
            "traefik.service"
          ];
          preStart = lib.mkBefore waitForPocketId;
        };

        services = {
          goroutinely = {
            enable = true;
            package = inputs.goroutinely.packages.${pkgs.stdenv.hostPlatform.system}.default;
            sendremindersPackage = inputs.goroutinely.packages.${pkgs.stdenv.hostPlatform.system}.sendreminders;
            port = 8235;
            host = "0.0.0.0";
            database.createLocally = true;
            notifications = {
              enable = true;
              vapidSubject = "mailto:admin@haseebmajid.dev";
              vapidPublicKey = "BN91igKCVVyiiDggAN4poSUaEKL_-CNV_3mnioXKghZd00x5fFkjLra8HvAhfwZkHTymFsXHsRwVYpTqyGja-II";
            };
            oauth = {
              issuerUrl = "https://id.haseebmajid.dev/.well-known/openid-configuration";
              clientId = "goroutinely";
            };
            secretsFile = config.sops.secrets.goroutinely.path;
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "goroutinely";
            port = 8235;
            subdomain = "goroutinely";
            domain = "haseebmajid.dev";
          };
        };

      };
  };
}
