{ ... }:
let
  mediaDir = "/mnt/homelab/homelab/paperless/media";
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.paperless = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/paperless";
        user = "paperless";
        group = "paperless";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        secrets,
        lib,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        users.users.${config.services.paperless.user}.extraGroups = [ "media" ];

        sops.secrets = {
          paperless_pass = { };
          paperless = { };
        };

        systemd = {
          tmpfiles.rules = [
            "d ${mediaDir} 0775 paperless media -"
            "d ${builtins.dirOf mediaDir} 0775 paperless media -"
          ];
          services = {
            paperless-web = {
              serviceConfig = {
                EnvironmentFile = [ secretPaths.paperless ];
                BindPaths = [ "/mnt/homelab" ];
              };
              requires = [ "mnt-homelab.mount" ];
              after = [
                "postgresql.service"
                "mnt-homelab.mount"
              ];
            };
            paperless-scheduler.serviceConfig.BindPaths = [ "/mnt/homelab" ];
            paperless-consumer.serviceConfig.BindPaths = [ "/mnt/homelab" ];
            paperless-task-queue.serviceConfig.BindPaths = [ "/mnt/homelab" ];
          };
        };

        services = {
          paperless = {
            enable = true;
            inherit mediaDir;
            passwordFile = secretPaths.paperless_pass;
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

          cloudflared.tunnels.${tunnelId}.ingress."paperless.haseebmajid.dev" = "http://localhost:28981";
        };

      };
  };
}
