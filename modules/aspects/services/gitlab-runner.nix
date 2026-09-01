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
          services.default = {
            authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
            limit = 4;
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
