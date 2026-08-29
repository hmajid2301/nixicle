_: {
  den.aspects.redis = {
    nixos =
      { pkgs, ... }:
      {
        services.redis = {
          package = pkgs.valkey;
          servers.main = {
            enable = true;
            openFirewall = false;
            port = 6380;
            bind = "127.0.0.1";
            unixSocket = "/run/redis-main/redis.sock";
            unixSocketPerm = 770;
          };
        };
      };
  };
}
