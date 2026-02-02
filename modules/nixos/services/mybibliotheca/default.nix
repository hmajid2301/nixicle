{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.mybibliotheca;
in {
  options.services.nixicle.mybibliotheca = {
    enable = mkEnableOption "mybibliotheca";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.mybibliotheca = {
        sopsFile = ../secrets.yaml;
      };

      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
      };

      networking.firewall.interfaces = let
        matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
      in {
        "${matchAll}".allowedUDPPorts = [53];
      };

      virtualisation.oci-containers.backend = "podman";

      systemd.tmpfiles.rules = [
        "d /var/lib/mybibliotheca 0750 root root -"
        "d /var/lib/mybibliotheca/kuzu 0750 root root -"
      ];

      virtualisation.oci-containers.containers."mybibliotheca" = {
        image = "pickles4evaaaa/mybibliotheca:beta-latest";
        environment = {
          "AUTO_MIGRATE" = "false";
          "GRAPH_DATABASE_ENABLED" = "true";
          "KUZU_DB_PATH" = "/app/data/kuzu";
          "LOG_LEVEL" = "INFO";
          "MYBIBLIOTHECA_VERBOSE_INIT" = "false";
          "SITE_NAME" = "MyBibliotheca";
          "TIMEZONE" = "Europe/London";
          "WORKERS" = "1";
        };
        environmentFiles = [
          config.sops.secrets.mybibliotheca.path
        ];
        volumes = [
          "/var/lib/mybibliotheca:/app/data:rw"
        ];
        ports = [
          "5054:5054/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=mybibliotheca"
          "--network=mybibliotheca_default"
        ];
      };

      systemd.services."podman-mybibliotheca" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
        };
        after = [
          "podman-network-mybibliotheca_default.service"
        ];
        requires = [
          "podman-network-mybibliotheca_default.service"
        ];
        partOf = [
          "podman-compose-mybibliotheca-root.target"
        ];
        upheldBy = [
          "podman-network-mybibliotheca_default.service"
        ];
        wantedBy = [
          "podman-compose-mybibliotheca-root.target"
        ];
      };

      systemd.services."podman-network-mybibliotheca_default" = {
        path = [pkgs.podman];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f mybibliotheca_default";
        };
        script = ''
          podman network inspect mybibliotheca_default || podman network create mybibliotheca_default
        '';
        partOf = ["podman-compose-mybibliotheca-root.target"];
        wantedBy = ["podman-compose-mybibliotheca-root.target"];
      };

      systemd.targets."podman-compose-mybibliotheca-root" = {
        unitConfig = {
          Description = "Root target for MyBibliotheca service";
        };
        wantedBy = ["multi-user.target"];
      };

      environment.persistence = mkIf config.system.impermanence.enable {
        "/persist" = {
          directories = [
            {
              directory = "/var/lib/mybibliotheca";
              user = "root";
              group = "root";
              mode = "0750";
            }
          ];
        };
      };
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "mybibliotheca.haseebmajid.dev" = "http://localhost:5054";
        };
      };
    }

    {
      services.traefik.dynamicConfigOptions.http = mkIf config.services.traefik.enable (
        lib.nixicle.mkTraefikService {
          name = "mybibliotheca";
          port = 5054;
          subdomain = "mybibliotheca";
          domain = "haseebmajid.dev";
        }
      );
    }
  ]);
}
