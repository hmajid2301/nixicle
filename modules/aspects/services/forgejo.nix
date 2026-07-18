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
      {
        directory = "/var/lib/forgejo-dind";
        user = "root";
        group = "root";
        mode = "0755";
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
          owner = "forgejo";
        };

        sops.secrets.forgejo_runner_token = {
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
            "d /var/lib/forgejo-dind 0755 root root -"
          ];

        };

        virtualisation.oci-containers = {
          backend = "docker";
          containers.forgejo-dind = {
            image = "docker:dind";
            autoStart = true;
            privileged = true;
            # Host networking avoids Tailscale routing table issues (table 52)
            # and Docker bridge conflicts — DIND can reach Docker Hub directly.
            # Use a non-conflicting bridge subnet so job containers inside DIND
            # can reach the DIND daemon via host-gateway.
            extraOptions = [
              "--network"
              "host"
            ];
            cmd = [
              # Listen on all interfaces (0.0.0.0) because dockerd needs to bind
              # BEFORE it creates the bridge at --bip. The firewall blocks external
              # access to port 2376. Job containers reach DIND via host-gateway
              # (172.20.0.1:2376 after dockerd creates the bridge).
              "dockerd"
              "-H"
              "tcp://0.0.0.0:2376"
              "--bip=172.20.0.1/16"
              "--tls=false"
            ];
            volumes = [ "/var/lib/forgejo-dind:/var/lib/docker" ];
          };
        };

        # bridge-nf-call-iptables=1 causes bridge traffic to go through iptables.
        # DIND cannot set up iptables (nft missing from docker:dind). Host rule
        # allows traffic from DIND bridge to the API port.
        networking.firewall.extraCommands = ''
          iptables -I nixos-fw 1 -p tcp --dport 2376 -s 172.20.0.0/16 -j ACCEPT 2>/dev/null || true
        '';
        networking.firewall.extraStopCommands = ''
          iptables -D nixos-fw -p tcp --dport 2376 -s 172.20.0.0/16 -j ACCEPT 2>/dev/null || true
        '';

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
                SSH_DOMAIN = "git.haseebmajid.dev";
                SSH_PORT = 2222;
                START_SSH_SERVER = true;
                SSH_LISTEN_PORT = 2223;
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
                  "docker:docker://ghcr.io/actions/actions-runner:latest"
                  "ubuntu-latest:docker://ghcr.io/actions/actions-runner:latest"
                  "ubuntu-22.04:docker://ghcr.io/actions/actions-runner:latest"
                  "ubuntu-20.04:docker://ghcr.io/actions/actions-runner:v2.308.0-ubuntu20.04"
                ];
                settings = {
                  runner.capacity = 4;

                  runner.envs.DOCKER_HOST = "tcp://dind_container.docker.internal:2376";
                  container.docker_host = "tcp://127.0.0.1:2376";
                  container.network = "bridge";
                  container.options = "--add-host=dind_container.docker.internal:host-gateway";
                };
              };
            };
          };
        };
      };
  };
}
