_: {
  den.aspects.anubis = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        port = 8923;
        domain = config.nixicle.domains.root;
        anubisDomain = "anubis.${domain}";
        bind = "127.0.0.1:${toString port}";
      in
      {
        systemd.services.anubis = {
          description = "Anubis proof-of-work challenge (Traefik forwardAuth)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            BIND = bind;
            # flagenv ignores empty env vars, so a single space disables
            # proxying: strings.TrimSpace(target) == "" (cmd/anubis/main.go).
            TARGET = " ";
            PUBLIC_URL = "https://${anubisDomain}";
            COOKIE_DOMAIN = domain;
            REDIRECT_DOMAINS = "${domain},*.${domain}";
            METRICS_BIND = "127.0.0.1:9090";
          };
          serviceConfig = {
            ExecStart = lib.getExe pkgs.anubis;
            Restart = "always";
            DynamicUser = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

        services.traefik.dynamicConfigOptions.http = {
          middlewares.anubis.forwardAuth.address = "http://${bind}/.within.website/x/cmd/anubis/api/check";
          routers.anubis = {
            entryPoints = [ "websecure" ];
            rule = "Host(`anubis.${domain}`)";
            service = "anubis";
            tls.certResolver = "letsencrypt";
          };
          services.anubis.loadBalancer.servers = [
            { url = "http://${bind}"; }
          ];
        };
      };
  };
}
