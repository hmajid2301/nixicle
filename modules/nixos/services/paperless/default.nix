{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.services.nixicle.paperless;
in
{
  options.services.nixicle.paperless = with types; {
    enable = mkBoolOpt false "Enable the paperless service";
    mediaDir =
      mkOpt str "/mnt/truenas/homelab/paperless/media"
        "Directory to store paperless media files";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.users.${config.services.paperless.user}.extraGroups = [ "media" ];

      sops.secrets.paperless_pass = {
        sopsFile = ../secrets.yaml;
      };

      sops.secrets.paperless = {
        sopsFile = ../secrets.yaml;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.mediaDir} 0775 paperless media -"
        "d ${dirOf cfg.mediaDir} 0775 paperless media -"
      ];

      systemd.services.paperless-web = {
        serviceConfig = {
          EnvironmentFile = [ config.sops.secrets.paperless.path ];
          BindPaths = mkIf (hasPrefix "/mnt/" cfg.mediaDir) [ "/mnt/truenas" ];
        };
        requires = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
        after = [
          "postgresql.service"
        ]
        ++ (optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount");
      };

      systemd.services.paperless-scheduler = {
        serviceConfig = {
          BindPaths = mkIf (hasPrefix "/mnt/" cfg.mediaDir) [ "/mnt/truenas" ];
        };
        requires = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
        after = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
      };

      systemd.services.paperless-consumer = {
        serviceConfig = {
          BindPaths = mkIf (hasPrefix "/mnt/" cfg.mediaDir) [ "/mnt/truenas" ];
        };
        requires = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
        after = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
      };

      systemd.services.paperless-task-queue = {
        serviceConfig = {
          BindPaths = mkIf (hasPrefix "/mnt/" cfg.mediaDir) [ "/mnt/truenas" ];
        };
        requires = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
        after = optional (hasPrefix "/mnt/truenas" cfg.mediaDir) "mnt-truenas.mount";
      };

      services = {
        paperless = {
          enable = true;
          mediaDir = cfg.mediaDir;
          passwordFile = config.sops.secrets.paperless_pass.path;

          settings = {
            PAPERLESS_DBHOST = "/run/postgresql";
            PAPERLESS_ALLOWED_HOSTS = "paperless.haseebmajid.dev,localhost,127.0.0.1";
            PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.haseebmajid.dev";
          };
        };

        postgresql = {
          ensureDatabases = [ "paperless" ];
          ensureUsers = [
            {
              name = "paperless";
              ensureDBOwnership = true;
            }
          ];
        };
      };

      environment.persistence = mkIf config.system.impermanence.enable {
        "/persist" = {
          directories = [
            {
              directory = "/var/lib/paperless";
              user = "paperless";
              group = "paperless";
              mode = "0750";
            }
          ];
        };
      };
    }

    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "paperless.haseebmajid.dev" = "http://localhost:28981";
        };
      };
    }
  ]);
}
