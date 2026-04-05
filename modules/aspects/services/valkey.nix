{ den, ... }:
{
  den.aspects.valkey = {
    nixos = { pkgs, ... }: {
      services.redis = {
        package = pkgs.valkey;
        servers.valkey = {
          enable = true;
          openFirewall = true;
          port = 6379;
          bind = "0.0.0.0";
        };
      };

      services.traefik.dynamicConfigOptions.tcp = {
        services.valkey.loadBalancer.servers = [ { address = "127.0.0.1:6379"; } ];
        routers.valkey = {
          entryPoints = [ "valkey" ];
          rule = "HostSNI(`*`)";
          service = "valkey";
        };
      };
    };
  };
}
