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
      let
        runnerPath = lib.makeBinPath [
          pkgs.coreutils
          pkgs.git
          pkgs.gnugrep
          pkgs.nix
          pkgs.openssh
        ];
      in
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
            dockerImage = "nixpkgs/nix-flakes:nixos-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.system}";
            dockerPullPolicy = "if-not-present";
            dockerPrivileged = false;
            dockerVolumes = [
              "/cache"
              "/certs/client"
              "/nix/store:/nix/store:ro"
              "/nix/var/nix/db:/nix/var/nix/db:ro"
              "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
              "/nix/var/nix/profiles/system/etc/ssl:/etc/ssl:ro"
              "${pkgs.bash}/bin/bash:/usr/bin/sh:ro"
              "${pkgs.bash}/bin/bash:/bin/bash:ro"
              "${pkgs.bash}/bin/bash:/usr/bin/bash:ro"
              "${pkgs.bash}/bin/bash:/bin/sh:ro"
            ];
            environmentVariables = {
              DOCKER_TLS_CERTDIR = "/certs";
              ENV = "/etc/profile";
              FF_NETWORK_PER_BUILD = "1";
              NIX_REMOTE = "daemon";
              PATH = "${runnerPath}:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/local/sbin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
              USER = "root";
            };
          };
        };

      };
  };
}
