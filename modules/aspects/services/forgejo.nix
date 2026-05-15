{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.forgejo = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/forgejo";
        user = "forgejo";
        group = "forgejo";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        sops.secrets.forgejo_smtp_password = {
          sopsFile = ../../../hosts/framebox/secrets.yaml;
          owner = "forgejo";
        };

        sops.secrets.forgejo_runner_token = {
          sopsFile = ../../../hosts/framebox/secrets.yaml;
        };

        systemd = {
          services.forgejo.preStart =
            let
              inherit (config.services.forgejo) stateDir;
              theme = pkgs.fetchzip {
                url = "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
                hash = "sha256-14XqO1ZhhPS7VDBSzqW55kh6n5cFZGZmvRCtMEh8JPI=";
                stripRoot = false;
              };
            in
            lib.mkAfter ''
              rm -rf ${stateDir}/custom/public/assets
              mkdir -p ${stateDir}/custom/public/assets
              ln -sf ${theme} ${stateDir}/custom/public/assets/css
            '';

          tmpfiles.rules = [
            "d /var/lib/forgejo 0750 forgejo forgejo -"
            "d /var/lib/forgejo/custom 0750 forgejo forgejo -"
            "d /var/lib/forgejo/custom/conf 0750 forgejo forgejo -"
            "d /var/lib/forgejo/backups 0775 forgejo forgejo -"
          ];
        };

        services = {
          forgejo = {
            enable = true;
            user = "forgejo";
            group = "forgejo";
            secrets.mailer.PASSWD = config.sops.secrets.forgejo_smtp_password.path;
            database = {
              socket = "/run/postgresql";
              type = "postgres";
            };
            settings = {
              server = {
                HTTP_PORT = 5706;
                DOMAIN = "forgejo.haseebmajid.dev";
                ROOT_URL = "https://forgejo.haseebmajid.dev/";
              };
              mailer = {
                ENABLED = true;
                PROTOCOL = "smtps";
                SMTP_PORT = 587;
                SMTP_ADDRESS = "smtp.mailgun.org";
                FROM = "do-not-reply@haseebmajid.dev";
                USER = "postmaster@sandbox92beea2c073042199273861834e24d1f.mailgun.org";
                SENDMAIL_PATH = "${pkgs.system-sendmail}/bin/sendmail";
              };
              ui = {
                DEFAULT_THEME = "catppuccin-mocha-lavender";
                THEMES = "gitea,arc-green,forgejo-auto,forgejo-light,forgejo-dark,gitea-auto,gitea-light,gitea-dark,catppuccin-latte-lavender,catppuccin-frappe-lavender,catppuccin-macchiato-lavender,catppuccin-mocha-lavender";
              };
            };
            dump = {
              backupDir = "/var/lib/forgejo/backups";
              enable = false;
              interval = "hourly";
              file = "forgejo-dump";
              type = "tar.zst";
            };
          };

          postgresql = {
            ensureDatabases = [ "forgejo" ];
            ensureUsers = [
              {
                name = "forgejo";
                ensureDBOwnership = true;
              }
            ];
          };

          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "forgejo";
            port = 5706;
            subdomain = "forgejo";
          };

          gitea-actions-runner = {
            package = pkgs.forgejo-runner;
            instances = {
              forgejo-runner = {
                enable = true;
                url = "https://forgejo.homelab.haseebmajid.dev";
                name = "homelab";
                tokenFile = config.sops.secrets.forgejo_runner_token.path;
                labels = [
                  "ubuntu-latest:docker://ghcr.io/actions/actions-runner:latest"
                  "ubuntu-22.04:docker://ghcr.io/actions/actions-runner:latest"
                  "ubuntu-20.04:docker://ghcr.io/actions/actions-runner:v2.308.0-ubuntu20.04"
                ];
              };
            };
          };

          cloudflared.tunnels.${tunnelId}.ingress = {
            "forgejo.haseebmajid.dev" = "http://localhost:5706";
          };
        };
      };
  };
}
