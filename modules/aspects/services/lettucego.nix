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
            "network.target"
          ];
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
