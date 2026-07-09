{ ... }:
{
  den.aspects.valkey = {
    nixos =
      { pkgs, ... }:
      {
        services.redis = {
          package = pkgs.valkey;
          servers.valkey = {
            enable = true;
            openFirewall = false;
            port = 6379;
            bind = "127.0.0.1";
          };
        };

      };
  };
}
