{lib, ...}: {
  # Create a standardized Traefik service configuration
  # Usage: mkTraefikService { name = "homepage"; port = 3000; subdomain = "home"; }
  mkTraefikService = {
    name,
    port,
    subdomain ? name,
    domain ? "homelab.haseebmajid.dev",
    entryPoints ? ["websecure"],
    certResolver ? "letsencrypt",
    middlewares ? [],
    extraRouterConfig ? {},
    extraServiceConfig ? {},
  }: {
    services.traefik.dynamicConfigOptions = {
      http = {
        routers.${name} = lib.mkMerge [
          {
            inherit entryPoints;
            rule = "Host(`${subdomain}.${domain}`)";
            service = name;
            tls.certResolver = certResolver;
            middlewares = middlewares;
          }
          extraRouterConfig
        ];

        services.${name} = lib.mkMerge [
          {
            loadBalancer = {
              servers = [{url = "http://localhost:${toString port}";}];
            };
          }
          extraServiceConfig
        ];
      };
    };
  };

  # Create a Traefik service with authentication middleware
  mkAuthenticatedTraefikService = args:
    lib.mkTraefikService (args
      // {
        middlewares = (args.middlewares or []) ++ ["authelia@file"];
      });
}
