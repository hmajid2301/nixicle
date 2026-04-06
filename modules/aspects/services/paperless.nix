{ den, lib, ... }:
let
  mediaDir = "/mnt/homelab/homelab/paperless/media";
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.paperless = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = "/var/lib/paperless"; user = "paperless"; group = "paperless"; mode = "0750"; }
        ];
    nixos = { config, lib, ... }: {
      users.users.${config.services.paperless.user}.extraGroups = [ "media" ];

      sops.secrets.paperless_pass.sopsFile = ../../../hosts/framebox/secrets.yaml;
      sops.secrets.paperless.sopsFile = ../../../hosts/framebox/secrets.yaml;

      systemd.tmpfiles.rules = [
        "d ${mediaDir} 0775 paperless media -"
        "d ${builtins.dirOf mediaDir} 0775 paperless media -"
      ];

      systemd.services.paperless-web = {
        serviceConfig = {
          EnvironmentFile = [ config.sops.secrets.paperless.path ];
          BindPaths = [ "/mnt/homelab" ];
        };
        requires = [ "mnt-homelab.mount" ];
        after = [ "postgresql.service" "mnt-homelab.mount" ];
      };
      systemd.services.paperless-scheduler.serviceConfig.BindPaths = [ "/mnt/homelab" ];
      systemd.services.paperless-consumer.serviceConfig.BindPaths = [ "/mnt/homelab" ];
      systemd.services.paperless-task-queue.serviceConfig.BindPaths = [ "/mnt/homelab" ];

      services.paperless = {
        enable = true;
        inherit mediaDir;
        passwordFile = config.sops.secrets.paperless_pass.path;
        settings = {
          PAPERLESS_DBHOST = "/run/postgresql";
          PAPERLESS_ALLOWED_HOSTS = "paperless.haseebmajid.dev,localhost,127.0.0.1";
          PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.haseebmajid.dev";
        };
      };

      services.postgresql = {
        ensureDatabases = [ "paperless" ];
        ensureUsers = [ { name = "paperless"; ensureDBOwnership = true; } ];
      };

      services.cloudflared.tunnels.${tunnelId}.ingress."paperless.haseebmajid.dev" = "http://localhost:28981";

    };
  };
}
