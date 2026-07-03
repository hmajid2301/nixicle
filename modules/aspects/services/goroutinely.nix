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
      {
        imports = [ inputs.goroutinely.nixosModules.default ];
        sops.secrets.goroutinely = {
                    key = "goroutinely";
          owner = config.services.goroutinely.user;
          inherit (config.services.goroutinely) group;
          mode = "0400";
        };

        services = {
          goroutinely = {
            enable = true;
            package = inputs.goroutinely.packages.${pkgs.stdenv.hostPlatform.system}.default;
            sendremindersPackage = inputs.goroutinely.packages.${pkgs.stdenv.hostPlatform.system}.default;
            port = 8235;
            host = "0.0.0.0";
            database.createLocally = true;
            notifications = {
              enable = true;
              vapidSubject = "mailto:admin@haseebmajid.dev";
              vapidPublicKey = "BN91igKCVVyiiDggAN4poSUaEKL_-CNV_3mnioXKghZd00x5fFkjLra8HvAhfwZkHTymFsXHsRwVYpTqyGja-II";
            };
            oauth = {
              issuerUrl = "https://authentik.haseebmajid.dev/application/o/go-routinely/.well-known/openid-configuration";
              clientId = "N3h5Y0H52Z96NqKfJn8fWasyPX5VRdtx5ps0uoWW";
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
