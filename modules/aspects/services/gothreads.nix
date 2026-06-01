{
  inputs,
  ...
}:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  flake-file.inputs.gothreads = {
    url = "gitlab:hmajid2301/gothreads";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.gothreads = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/gothreads";
        user = "gothreads";
        group = "gothreads";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ inputs.gothreads.nixosModules.default ];

        sops.secrets.gothreads = {
          sopsFile = ../../../hosts/framebox/secrets.yaml;
          key = "gothreads";
          owner = config.services.gothreads.user;
          inherit (config.services.gothreads) group;
          mode = "0400";
        };

        systemd.services.gothreads.after = [
          "garage.service"
          "postgresql.service"
        ];
        systemd.services.gothreads.requires = [ "garage.service" ];
        systemd.services.gothreads.environment.GOTHREADS_OLLAMA_TEXT_MODEL = lib.mkForce "llama3.2";

        services = {
          gothreads = {
            enable = true;
            package = inputs.gothreads.packages.${pkgs.stdenv.hostPlatform.system}.default;
            address = "0.0.0.0";
            port = 8556;
            database.createLocally = true;
            secretsFile = config.sops.secrets.gothreads.path;
            oauth = {
              issuerUrl = "https://authentik.haseebmajid.dev/application/o/gothreads/";
              clientId = "UMLLRCgGhl1ljj48lbhTVMCyulz77hMl6ELEKHUI";
            };
            s3 = {
              endpoint = "http://127.0.0.1:3900";
              region = "garage";
            };
          };

          cloudflared.tunnels.${tunnelId}.ingress."gothreads.haseebmajid.dev" = "http://localhost:8556";
        };
      };
  };
}
