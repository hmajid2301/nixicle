{
  den,
  inputs,
  lib,
  ...
}:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  flake-file.inputs.goroutinely = {
    url = "gitlab:hmajid2301/goroutinely/feat/move-to-internal";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.goroutinely = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
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
          sopsFile = ../../../hosts/framebox/secrets.yaml;
          key = "goroutinely";
          owner = config.services.goroutinely.user;
          inherit (config.services.goroutinely) group;
          mode = "0400";
        };

        services = {
          goroutinely = {
            enable = true;
            package = inputs.goroutinely.packages.${pkgs.system}.default;
            sendremindersPackage = inputs.goroutinely.packages.${pkgs.system}.default;
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

          cloudflared.tunnels.${tunnelId}.ingress."goroutinely.haseebmajid.dev" = "http://localhost:8235";

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
