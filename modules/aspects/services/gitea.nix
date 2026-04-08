{ den, lib, ... }:
{
  den.aspects.gitea = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = "/var/lib/gitea"; user = "gitea"; group = "gitea"; mode = "0750"; }
        ];
    nixos = { config, pkgs, lib, ... }: {
      sops.secrets.gitea_smtp_password = {
        sopsFile = ../../../hosts/framebox/secrets.yaml;
        owner = "gitea";
      };

      systemd = {
        services.gitea.preStart =
          let inherit (config.services.gitea) stateDir;
              theme = pkgs.fetchzip {
                url = "https://github.com/catppuccin/gitea/releases/download/v0.4.1/catppuccin-gitea.tar.gz";
                hash = "sha256-14XqO1ZhhPS7VDBSzqW55kh6n5cFZGZmvRCtMEh8JPI=";
                stripRoot = false;
              };
          in lib.mkAfter ''
            rm -rf ${stateDir}/custom/public/assets
            mkdir -p ${stateDir}/custom/public/assets
            ln -sf ${theme} ${stateDir}/custom/public/assets/css
          '';

        tmpfiles.rules = [
          "d /var/lib/gitea 0750 gitea gitea -"
          "d /var/lib/gitea/custom 0750 gitea gitea -"
          "d /var/lib/gitea/custom/conf 0750 gitea gitea -"
          "d /var/lib/gitea/backups 0775 gitea gitea -"
        ];
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
              DOMAIN = "git.homelab.haseebmajid.dev";
              ROOT_URL = "https://git.homelab.haseebmajid.dev/";
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
            ui.DEFAULT_THEME = "catppuccin-mocha-lavendar";
          };
          dump = {
            backupDir = "/var/lib/gitea/backups";
            enable = false;
            interval = "hourly";
            file = "gitea-dump";
            type = "tar.zst";
          };
        };

        postgresql = {
          ensureDatabases = [ "gitea" ];
          ensureUsers = [ { name = "gitea"; ensureDBOwnership = true; } ];
        };

        traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "gitea";
          port = 5705;
          subdomain = "git";
        };
      };
    };
  };
}
