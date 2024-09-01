{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.gitea;
  theme = pkgs.fetchzip {
    url = "https://github.com/catppuccin/gitea/releases/download/v0.4.1/catppuccin-gitea.tar.gz";
    hash = "sha256-14XqO1ZhhPS7VDBSzqW55kh6n5cFZGZmvRCtMEh8JPI=";
    stripRoot = false;
  };
in {
  options.services.nixicle.gitea = {
    enable = mkEnableOption "Enable gitea self hosted git server";
  };

  config = mkIf cfg.enable {
    sops.secrets.gitea_smtp_password = {
      sopsFile = ../secrets.yaml;
      owner = "gitea";
    };

    systemd.services = {
      gitea = {
        preStart = let
          inherit (config.services.gitea) stateDir;
        in
          mkAfter ''
            rm -rf ${stateDir}/custom/public/assets
            mkdir -p ${stateDir}/custom/public/assets
            ln -sf ${theme} ${stateDir}/custom/public/assets/css
          '';
      };
    };

    services = {
      gitea = {
        enable = true;
        user = "gitea";
        group = "gitea";
        mailerPasswordFile = config.sops.secrets.gitea_smtp_password.path;
        database = {
          socket = "/run/postgresql";
          type = "postgres";
        };
        settings = {
          server = {
            HTTP_PORT = 5705;
            DOMAIN = "git.bare.homelab.haseebmajid.dev";
            ROOT_URL = "https://git.bare.homelab.haseebmajid.dev/";
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
            DEFAULT_THEME = "catppuccin-mocha-lavendar";
          };
        };
        dump = {
          backupDir = "/mnt/share/gitea/backups";
          enable = false;
          interval = "hourly";
          file = "gitea-dump";
          type = "tar.zst";
        };
      };

      postgresql = {
        ensureDatabases = ["gitea"];
        ensureUsers = [
          {
            name = "gitea";
            ensureDBOwnership = true;
          }
        ];
      };

      traefik = {
        dynamicConfigOptions = {
          http = {
            services.gitea.loadBalancer.servers = [
              {
                url = "http://localhost:5705";
              }
            ];

            routers = {
              gitea = {
                entryPoints = ["websecure"];
                rule = "Host(`git.bare.homelab.haseebmajid.dev`)";
                service = "gitea";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}
