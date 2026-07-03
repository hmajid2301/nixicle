{
  inputs,
  ...
}:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
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
              issuerUrl = "https://authentik.haseebmajid.dev/application/o/lettucego/";
              clientId = "4xkxfKIj6aYPvnlTpvCvRN58cWBTQMxPNhnd5YXp";
            };
            secretsFile = config.sops.secrets.lettucego.path;
          };

          cloudflared.tunnels.${tunnelId}.ingress."lettucego.haseebmajid.dev" = "http://localhost:8236";
        };
      };
  };
}
