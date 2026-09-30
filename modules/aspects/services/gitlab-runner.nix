{ den, ... }:
{
  den.aspects.gitlab-runner = {
    includes = [ den.aspects.docker ];
    persist.directories = [
      {
        directory = "/var/lib/private/gitlab-runner";
        user = "root";
        group = "root";
        mode = "0750";
      }
    ];
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        isDesktop = config.networking.hostName == "desktop";
        desktopResourceFlags = lib.optionals isDesktop [
          "--docker-cpus=3"
          "--docker-memory=12g"
          "--docker-memory-swap=16g"
          "--docker-service-cpus=1.5"
          "--docker-service-memory=3g"
          "--docker-services-limit=4"
        ];
      in
      {
        virtualisation.docker = {
          enable = true;
          liveRestore = false;
        };

        services.gitlab-runner = lib.mkMerge [
          {
            enable = true;
            settings = {
              concurrent = if isDesktop then 6 else 4;
              check_interval = 3;
              listen_address = "127.0.0.1:9252";
            };
            services.default = {
              authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
              limit = if isDesktop then 6 else 3;
              requestConcurrency = 2;
              registrationFlags = desktopResourceFlags;
              dockerImage = "nixpkgs/nix-flakes:nixos-26.05-${pkgs.stdenv.hostPlatform.system}";
              dockerPullPolicy = "if-not-present";
              dockerPrivileged = true;
              preBuildScript = pkgs.writeScript "setup-container" ''
                mkdir -p -m 0755 /etc/nix
                touch /etc/nix/nix.conf
                mkdir -p -m 0755 /nix/var/log/nix/drvs
                mkdir -p -m 0755 /nix/var/nix/gcroots
                mkdir -p -m 0755 /nix/var/nix/profiles
                mkdir -p -m 0755 /nix/var/nix/temproots
                mkdir -p -m 0755 /nix/var/nix/userpool
                mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
                mkdir -p -m 1777 /nix/var/nix/profiles/per-user
                mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
                mkdir -p -m 0700 "$HOME/.nix-defexpr"

                . ${pkgs.nix}/etc/profile.d/nix-daemon.sh

                ${pkgs.nix}/bin/nix-env -i ${
                  lib.escapeShellArgs (
                    with pkgs;
                    [
                      nix
                      cacert
                      git
                      openssh
                      attic-client
                      docker-client
                      findutils
                    ]
                  )
                }
              '';
              dockerVolumes = [
                "/cache"
                "/certs/client"
                "/nix/store:/nix/store:ro"
                "/nix/var/nix/db:/nix/var/nix/db:ro"
                "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
                "/nix/var/nix/profiles/system/etc/ssl:/etc/nixicle-ssl:ro"
                "${lib.getExe pkgs.pkgsStatic.gnugrep}:/usr/bin/grep:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "mkdir"}:/usr/bin/mkdir:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "rm"}:/usr/bin/rm:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "chmod"}:/usr/bin/chmod:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "cat"}:/usr/bin/cat:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "touch"}:/usr/bin/touch:ro"
                "${lib.getExe pkgs.pkgsStatic.bash}:/usr/bin/sh:ro"
                "${lib.getExe pkgs.pkgsStatic.bash}:/usr/bin/bash:ro"
              ];
              environmentVariables = {
                COMPOSE_PARALLEL_LIMIT = "2";
                DOCKER_TLS_CERTDIR = "/certs";
                ENV = "/etc/profile";
                FF_NETWORK_PER_BUILD = "1";
                NIX_REMOTE = "daemon";
                NIX_SSL_CERT_FILE = "/etc/nixicle-ssl/certs/ca-bundle.crt";
                PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin";
                SSL_CERT_FILE = "/etc/nixicle-ssl/certs/ca-bundle.crt";
                USER = "root";
              };
            };
          }
          (lib.optionalAttrs (config.sops.secrets ? gitlab_runner_docker_env) {
            services.docker = {
              authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_docker_env.path;
              limit = if isDesktop then 6 else 4;
              requestConcurrency = 2;
              registrationFlags = desktopResourceFlags;
              dockerImage = "nixpkgs/nix-flakes:nixos-26.05-${pkgs.stdenv.hostPlatform.system}";
              dockerPullPolicy = "if-not-present";
              dockerPrivileged = true;
              dockerVolumes = [
                "/cache"
                "/certs/client"
                "${lib.getExe pkgs.pkgsStatic.gnugrep}:/usr/bin/grep:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "mkdir"}:/usr/bin/mkdir:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "rm"}:/usr/bin/rm:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "chmod"}:/usr/bin/chmod:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "cat"}:/usr/bin/cat:ro"
                "${lib.getExe' pkgs.pkgsStatic.coreutils "touch"}:/usr/bin/touch:ro"
                "${lib.getExe pkgs.pkgsStatic.bash}:/usr/bin/sh:ro"
                "${lib.getExe pkgs.pkgsStatic.bash}:/usr/bin/bash:ro"
              ];
              environmentVariables = {
                COMPOSE_PARALLEL_LIMIT = "2";
                DOCKER_TLS_CERTDIR = "/certs";
                ENV = "/etc/profile";
                FF_NETWORK_PER_BUILD = "1";
                PATH = "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin";
                USER = "root";
              };
            };
          })
        ];

        # The runner never cleans up its docker cache volumes
        # (https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27332) and they
        # accumulate per runner-ID rotation (~6 volumes per ID, forever).
        # Prune them weekly. `docker volume rm` refuses in-use volumes, so any
        # cache belonging to a runner mid-job is skipped automatically and we
        # don't need to pause the runner. Removing an idle cache volume only
        # costs a cache miss on the next job that used it.
        systemd.services.gitlab-runner-cache-prune = {
          description = "Prune orphaned gitlab-runner docker cache volumes";
          after = [ "docker.service" ];
          requires = [ "docker.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          path = [
            pkgs.docker
            pkgs.gnugrep
            pkgs.findutils
          ];
          script = ''
            set -euo pipefail
            volumes=$(${pkgs.docker}/bin/docker volume ls -q --filter name=runner- 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -E '^runner-[0-9a-f]{32}-cache-[0-9a-f]{32}(-protected)?$' || true)
            if [ -n "$volumes" ]; then
              count=$(printf '%s\n' "$volumes" | wc -l)
              echo "Pruning $count orphaned runner cache volumes..."
              printf '%s\n' "$volumes" \
                | ${pkgs.findutils}/bin/xargs -r ${pkgs.docker}/bin/docker volume rm 2>&1 || true
            else
              echo "No runner cache volumes to prune."
            fi
          '';
        };

        systemd.timers.gitlab-runner-cache-prune = {
          description = "Weekly prune of orphaned gitlab-runner cache volumes";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "Sun *-*-* 04:00:00";
            Persistent = true;
            RandomizedDelaySec = "10m";
          };
        };
      };
  };
}
