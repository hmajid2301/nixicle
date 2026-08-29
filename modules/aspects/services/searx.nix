_: {
  den.aspects.searx = {
    nixos =
      { config, ... }:
      {
        sops = {
          secrets.searx_secret_key = { };
          templates."searx-env".content = ''
            SEARX_SECRET_KEY=${config.sops.placeholder.searx_secret_key}
          '';
        };
        services.searx = {
          enable = true;
          environmentFile = config.sops.templates."searx-env".path;
          settings = {
            server = {
              bind_address = "127.0.0.1";
              port = 8082;
              secret_key = "$SEARX_SECRET_KEY";
            };
            search.formats = [
              "html"
              "json"
            ];
            valkey = {
              url = "valkey://localhost:6380/0";
            };
          };
        };
      };
  };
}
