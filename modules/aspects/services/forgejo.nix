{ den, ... }:
{
  den.aspects.forgejo = {
    includes = [ den.aspects.docker ];

    persist.directories = [
      {
        directory = "/var/lib/forgejo";
        user = "forgejo";
        group = "forgejo";
        mode = "0750";
      }
      {
        directory = "/var/lib/private/forgejo-runner";
        user = "root";
        group = "root";
        mode = "0700";
      }
    ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = config.services.forgejo;
        port = 5706;
        sshPort = 2222;
        domain = config.nixicle.domains.root;
        host = "forgejo.${domain}";
        oidcName = "pocketid";
        forgejoExe = lib.getExe cfg.package;
        forgejoEnv = {
          USER = cfg.user;
          HOME = cfg.stateDir;
          FORGEJO_WORK_DIR = cfg.stateDir;
          FORGEJO_CUSTOM = cfg.customDir;
        };

        toUuid =
          id:
          let
            hex = lib.concatMapStrings (c: lib.toLower (lib.toHexString (lib.strings.charToInt c))) (
              lib.stringToCharacters id
            );
          in
          lib.concatStringsSep "-" [
            (lib.substring 0 8 hex)
            (lib.substring 8 4 hex)
            (lib.substring 12 4 hex)
            (lib.substring 16 4 hex)
            (lib.substring 20 12 hex)
          ];
        runnerSecretFile = name: "${cfg.stateDir}/actions-runner-${name}-secret";
        runners = {
          nix = {
            id = "6e697869636c6e78";
            labels = [ "nix:docker://forgejo-nix:latest" ];
            capacity = 2;
            container = {
              valid_volumes = [
                "/nix/store"
                "/nix/var/nix/daemon-socket"
              ];
              options = lib.concatStringsSep " " [
                "--user ${jobUid}:${jobUid}"
                "-v /nix/store:/nix/store:ro"
                "-v /nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
              ];
            };
          };
          docker = {
            id = "6e697869636c6463";
            labels = [
              "docker:docker://data.forgejo.org/oci/node:22-bookworm"
              "ubuntu-latest:docker://data.forgejo.org/oci/node:22-bookworm"
            ];
            capacity = 1;
            container = { };
          };
        };

        jobUid = "30000";
        jobTools = pkgs.buildEnv {
          name = "forgejo-nix-job-tools";
          paths = with pkgs; [
            bashInteractive
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            gnutar
            gzip
            xz
            zstd
            curl
            jq
            git
            openssh
            nix
            nodejs
            cacert
          ];
          pathsToLink = [
            "/bin"
            "/etc/ssl"
          ];
        };

        nixJobImage = pkgs.dockerTools.buildImage {
          name = "forgejo-nix";
          tag = "latest";
          extraCommands = ''
            mkdir -p etc/nix usr/bin root
            mkdir -m 1777 tmp workspace
            ln -s ${jobTools}/bin bin
            ln -s ${jobTools}/bin/env usr/bin/env
            ln -s ${jobTools}/etc/ssl etc/ssl
            echo "root:x:0:0::/root:/bin/sh" > etc/passwd
            echo "ci:x:${jobUid}:${jobUid}::/tmp:/bin/sh" >> etc/passwd
            echo "root:x:0:" > etc/group
            echo "ci:x:${jobUid}:" >> etc/group
            echo "hosts: files dns" > etc/nsswitch.conf
            echo "experimental-features = nix-command flakes" > etc/nix/nix.conf
          '';
          config = {
            User = "${jobUid}:${jobUid}";
            WorkingDir = "/tmp";
            Env = [
              "PATH=/bin"
              "HOME=/tmp"
              "NIX_REMOTE=daemon"
              "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };
      in
      {
        sops.secrets.forgejo_oidc_client_secret = {
          owner = cfg.user;
          restartUnits = [ "forgejo-oidc.service" ];
        };

        networking.firewall.allowedTCPPorts = [ sshPort ];

        system.backup.objects.forgejo = {
          paths = [ cfg.stateDir ];
          exclude = [ "${cfg.stateDir}/data/tmp" ];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "2h";
            Persistent = true;
          };
        };

        systemd.services = {
          forgejo.preStart =
            let
              theme = pkgs.fetchzip {
                url = "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
                hash = "sha256-rZHLORwLUfIFcB6K9yhrzr+UwdPNQVSadsw6rg8Q7gs=";
                stripRoot = false;
              };
            in
            lib.mkAfter ''
              rm -rf ${cfg.customDir}/public/assets
              mkdir -p ${cfg.customDir}/public/assets
              ln -sf ${theme} ${cfg.customDir}/public/assets/css
            '';

          forgejo-dirs = {
            description = "Create Forgejo state directories";
            unitConfig.RequiresMountsFor = [ cfg.stateDir ];
            before = [
              "forgejo-secrets.service"
              "forgejo.service"
            ];
            requiredBy = [
              "forgejo-secrets.service"
              "forgejo.service"
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              install -d -m 0750 -o ${cfg.user} -g ${cfg.group} ${cfg.stateDir} ${cfg.customDir} ${cfg.customDir}/conf
            '';
          };

          forgejo-oidc = {
            description = "Configure the Pocket ID login source for Forgejo";
            after = [
              "forgejo.service"
              "pocket-id.service"
            ];
            requires = [ "forgejo.service" ];
            wantedBy = [ "multi-user.target" ];
            environment = forgejoEnv;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = cfg.user;
              Group = cfg.group;
              WorkingDirectory = cfg.stateDir;
            };
            script = ''
              set -euo pipefail
              secret="$(cat ${config.sops.secrets.forgejo_oidc_client_secret.path})"
              args=(
                --name ${oidcName}
                --provider openidConnect
                --key forgejo
                --secret "$secret"
                --auto-discover-url https://${config.nixicle.domains.sso}/.well-known/openid-configuration
                --scopes profile
                --scopes email
                --scopes groups
                --group-claim-name groups
                --admin-group forgejo_admins
                --skip-local-2fa
              )
              id="$(${forgejoExe} admin auth list | ${lib.getExe pkgs.gawk} -v n=${oidcName} '$2 == n { print $1 }')"
              if [ -n "$id" ]; then
                ${forgejoExe} admin auth update-oauth --id "$id" "''${args[@]}"
              else
                ${forgejoExe} admin auth add-oauth "''${args[@]}"
              fi
            '';
          };

          forgejo-runner-register = {
            description = "Register the Forgejo Actions runner";
            after = [ "forgejo.service" ];
            requires = [ "forgejo.service" ];
            environment = forgejoEnv;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = cfg.user;
              Group = cfg.group;
              WorkingDirectory = cfg.stateDir;
              UMask = "0077";
            };
            script = lib.concatStrings (
              lib.mapAttrsToList (name: runner: ''
                if [ ! -s ${runnerSecretFile name} ]; then
                  printf '%s%s' ${runner.id} "$(${lib.getExe pkgs.openssl} rand -hex 12)" > ${runnerSecretFile name}
                fi
                ${forgejoExe} forgejo-cli actions register \
                  --name ${config.networking.hostName}-${name} \
                  --labels ${lib.concatMapStringsSep "," (l: lib.head (lib.splitString ":" l)) runner.labels} \
                  --secret-file ${runnerSecretFile name}
              '') runners
            );
          };

          forgejo-nix-image = {
            description = "Load the Forgejo Actions nix job image";
            after = [ "docker.service" ];
            requires = [ "docker.service" ];
            path = [ config.virtualisation.docker.package ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "docker load < ${nixJobImage}";
          };
        }
        // lib.mapAttrs' (
          name: _:
          let
            deps = [
              "forgejo-runner-register.service"
            ]
            ++ lib.optional (name == "nix") "forgejo-nix-image.service";
          in
          lib.nameValuePair "forgejo-runner-${name}" {
            after = deps;
            requires = deps;
          }
        ) runners;

        services = {
          forgejo = {
            enable = true;
            database = {
              type = "postgres";
              socket = "/run/postgresql";
            };
            lfs.enable = true;
            settings = {
              DEFAULT.APP_NAME = "Forgejo";
              server = {
                HTTP_ADDR = "127.0.0.1";
                HTTP_PORT = port;
                DOMAIN = host;
                ROOT_URL = "https://${host}/";
                START_SSH_SERVER = true;
                BUILTIN_SSH_SERVER_USER = "git";
                SSH_DOMAIN = "git.${domain}";
                SSH_PORT = sshPort;
                SSH_LISTEN_PORT = sshPort;
              };
              session.COOKIE_SECURE = true;
              service = {
                DISABLE_REGISTRATION = false;
                ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
                SHOW_REGISTRATION_BUTTON = false;
                ENABLE_INTERNAL_SIGNIN = false;
                ENABLE_BASIC_AUTHENTICATION = false;
              };
              openid = {
                ENABLE_OPENID_SIGNIN = false;
                ENABLE_OPENID_SIGNUP = false;
              };
              oauth2_client = {
                ENABLE_AUTO_REGISTRATION = true;
                USERNAME = "preferred_username";
                ACCOUNT_LINKING = "auto";
                UPDATE_AVATAR = true;
              };
              actions.ENABLED = true;
              ui = {
                DEFAULT_THEME = "catppuccin-mocha-lavender";
                THEMES = "forgejo-auto,forgejo-light,forgejo-dark,catppuccin-latte-lavender,catppuccin-frappe-lavender,catppuccin-macchiato-lavender,catppuccin-mocha-lavender";
              };
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
            inherit port domain;
          };

          forgejo-runner.instances = lib.mapAttrs (name: runner: {
            enable = true;
            secrets.server.connections.default.token_url = runnerSecretFile name;
            settings = {
              server.connections.default = {
                url = "http://127.0.0.1:${toString port}/";
                uuid = toUuid runner.id;
              };
              runner = {
                inherit (runner) labels capacity;
                timeout = "1h";
              };
              cache.enabled = true;
              container = {
                force_pull = false;
              }
              // runner.container;
            };
          }) runners;
        };
      };
  };
}
