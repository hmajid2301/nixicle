{
  inputs,
  ...
}:
{
  flake-file.inputs.lettucego = {
    url = "gitlab:hmajid2301/lettucego";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.lettucego = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/lettucego";
        user = "lettucego";
        group = "lettucego";
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
        imports = [ inputs.lettucego.nixosModules.default ];

        sops.secrets.lettucego = {
          key = "lettucego";
          owner = config.services.lettucego.user;
          inherit (config.services.lettucego) group;
          mode = "0400";
        };

        systemd.services.lettucego = {
          after = lib.mkForce [
            "garage.service"
            "postgresql.service"
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
          environment.LETTUCEGO_S3_PUBLIC_URL = "https://lettucego.haseebmajid.dev/lettucego";
        };

        services = {
          lettucego = {
            enable = true;
            package = inputs.lettucego.packages.${pkgs.stdenv.hostPlatform.system}.default;
            port = 8236;
            host = "0.0.0.0";
            database.createLocally = true;
            s3 = {
              endpoint = "http://127.0.0.1:3900";
              region = "garage";
            };
            oauth = {
              issuerUrl = "https://id.haseebmajid.dev";
              clientId = "lettucego";
              provider = "pocketid";
            };
            secretsFile = config.sops.secrets.lettucego.path;
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "lettucego";
            port = 8236;
            subdomain = "lettucego";
            domain = "haseebmajid.dev";
          };
        };
      };
  };
}
