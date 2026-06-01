{ ... }:
{
  den.aspects.searx = {
    nixos =
      { config, ... }:
      {
        sops.secrets.searx_secret_key.sopsFile = ../../../hosts/framebox/secrets.yaml;

        services.searx = {
          enable = true;
          environmentFile = config.sops.secrets.searx_secret_key.path;
          settings = {
            server.bind_address = "127.0.0.1";
            server.port = 8082;
            server.secret_key = "$SEARX_SECRET_KEY";
            valkey = {
              url = "valkey://localhost:6379/0";
            };
          };
        };
      };
  };
}