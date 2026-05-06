{ den, lib, ... }:
{
  den.aspects.gitlab-runner = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/private/gitlab-runner";
        user = "gitlab-runner";
        group = "gitlab-runner";
        mode = "0750";
        defaultPerms.mode = "0700";
      }
    ];
    nixos =
      { config, ... }:
      {
        virtualisation.docker = {
          enable = true;
          liveRestore = false;
        };

        systemd.services.gitlab-runner.serviceConfig.SupplementaryGroups = [ "docker" ];

        services.gitlab-runner = {
          enable = true;
          settings = {
            concurrent = 10;
            check_interval = 3;
          };
          services.default = {
            authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
            limit = 10;
            requestConcurrency = 4;
            dockerImage = "debian:stable";
            dockerPrivileged = true;
            dockerVolumes = [
              "/cache"
              "/certs/client"
            ];
            environmentVariables.DOCKER_TLS_CERTDIR = "/certs";
          };
        };

      };
  };
}
