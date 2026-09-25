_: {
  den.aspects.papra = {
    persist.directories = [
      {
        directory = "/var/lib/papra";
        user = "papra";
        group = "papra";
        mode = "0750";
      }
    ];
    nixos =
      { config, lib, ... }:
      let
        domain = "papra.${config.nixicle.domains.root}";
        port = 1221;
      in
      {
        system.backup.objects.papra.paths = [ "/var/lib/papra" ];
        sops.secrets.papra-env = {
          restartUnits = [ "papra.service" ];
        };

        services.papra = {
          enable = true;
          environmentFiles = [ config.sops.secrets.papra-env.path ];
          environment = {
            APP_BASE_URL = "https://${domain}";
            NODE_ENV = "production";
            SERVER_HOSTNAME = "127.0.0.1";
            DOCUMENT_STORAGE_ENCRYPTION_IS_ENABLED = "true";
            AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "papra";
          inherit port;
          subdomain = "papra";
          domain = config.nixicle.domains.root;
          extraServiceConfig.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString port}"; }
          ];
        };
      };
  };
}
