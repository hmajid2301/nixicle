{ ... }:
{
  den.aspects.redis = {
    nixos = _: {
      services.redis.servers.main = {
        enable = true;
        openFirewall = true;
        port = 6380;
        bind = "0.0.0.0";
        unixSocket = "/run/redis-main/redis.sock";
        unixSocketPerm = 770;
      };

      services.traefik.dynamicConfigOptions.tcp = {
        services.redis.loadBalancer.servers = [ { address = "127.0.0.1:6380"; } ];
        routers.redis = {
          entryPoints = [ "redis" ];
          rule = "HostSNI(`*`)";
          service = "redis";
        };
      };
    };
  };
}
