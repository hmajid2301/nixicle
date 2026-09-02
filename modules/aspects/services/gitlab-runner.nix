{ den, ... }:
{
  den.aspects.gitlab-runner = {
    includes = [ den.aspects.docker ];
    persist.directories = [
      {
        # DynamicUser services store StateDirectory under /var/lib/private; no
        # stable gitlab-runner user exists during impermanence activation.
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
      {
        virtualisation.docker = {
          enable = true;
          liveRestore = false;
        };

        services.gitlab-runner = {
          enable = true;
          settings = {
            concurrent = 4;
            check_interval = 3;
            listen_address = "127.0.0.1:9252";
          };
          # Untagged runner for nixicle CI: builds against the host nix
          # daemon and store (nix-fast-build, attic pushes), privileged for
          # tailscale deploys. Host-store mounts mask any job image's own
          # /nix/store, so only jobs that want host nix should land here.
          services.default = {
            authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
            limit = 3;
            requestConcurrency = 2;
            dockerImage = "nixpkgs/nix-flakes:nixos-26.05-${pkgs.stdenv.hostPlatform.system}";
            dockerPullPolicy = "if-not-present";
            dockerPrivileged = true;
            preBuildScript = pkgs.writeScript "setup-container" ''
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
              "/nix/var/nix/profiles/system/etc/ssl:/etc/ssl:ro"
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
              DOCKER_TLS_CERTDIR = "/certs";
              ENV = "/etc/profile";
              FF_NETWORK_PER_BUILD = "1";
              NIX_REMOTE = "daemon";
              NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
              PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin";
              SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
              USER = "root";
            };
          };
          # Tagged "docker" runner for jobs on prebuilt nix images such as
          # lettucego ci:vX: plain executor keeps each image's own /nix/store
          # intact, privileged allows docker:dind services. Tags live on the
          # token GitLab-side (run-untagged off), so jobs opt in with
          # `tags: [docker]`.
          services.docker = {
            authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_docker_env.path;
            limit = 2;
            requestConcurrency = 2;
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
              DOCKER_TLS_CERTDIR = "/certs";
              ENV = "/etc/profile";
              FF_NETWORK_PER_BUILD = "1";
              PATH = "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin";
              USER = "root";
            };
          };
        };

      };
  };
}
