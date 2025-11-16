{lib, ...}: {
  # Create a standardized Traefik service configuration
  # Returns router and service config that should be assigned to dynamicConfigOptions.http
  # Usage in modules: services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService { ... };
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

  # Create a Traefik service with Authentik authentication middleware
  mkAuthenticatedTraefikService = {
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
    routers.${name} = lib.mkMerge [
      {
        inherit entryPoints;
        rule = "Host(`${subdomain}.${domain}`)";
        service = name;
        tls.certResolver = certResolver;
        middlewares = middlewares ++ ["authentik"];
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
}
